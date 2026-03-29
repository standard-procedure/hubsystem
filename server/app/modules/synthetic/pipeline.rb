# frozen_string_literal: true

class Synthetic
  class Pipeline
    attr_reader :synthetic

    def initialize(synthetic)
      @synthetic = synthetic
      @preprocessor = Preprocessor.new(synthetic)
      @governor = Governor.new(synthetic)
      @postprocessor = Postprocessor.new(synthetic)
    end

    def process(message)
      update_state(:busy)

      # 1. Pre-process: threat assessment + incoming emotion (concurrent)
      preprocess = @preprocessor.process(message)
      if preprocess.blocked
        update_state_from_fatigue
        return blocked_response(preprocess.reason)
      end

      # 2. Process: LLM generates a response
      context = synthetic.ensure_llm_context
      context.with_model(llm_model(synthetic.llm_tier))
      context.with_instructions(synthetic.operating_system) if synthetic.operating_system.present? && context.llm_context_messages.empty?
      context.with_tools(*tools)
      response_text = context.ask(message).content

      # 3. Govern: check the response is appropriate
      governance = @governor.process(response_text)
      response_text = Governor::REFUSAL_MESSAGE unless governance.approved

      # 4. Post-process: memory + outgoing emotion (concurrent) + capacity
      @postprocessor.process(response_text)

      update_state_from_fatigue
      response_text
    end

    private

    def tools
      [
        ReadMemoryTool.new(synthetic),
        WriteMemoryTool.new(synthetic),
        ReadDocumentTool.new(synthetic),
        WriteDocumentTool.new(synthetic),
        ListConversationsTool.new(synthetic),
        StartConversationTool.new(synthetic),
        SendMessageTool.new(synthetic),
        CreateTaskTool.new(synthetic),
        AssignTaskTool.new(synthetic),
        CompleteTaskTool.new(synthetic),
        ListTasksTool.new(synthetic),
        RunCommandTool.new(synthetic),
        SkillLoaderTool.new(synthetic)
      ]
    end

    def llm_model(tier)
      Rails.application.config.llm_models[tier.to_s]
    end

    def update_state(state)
      synthetic.update_column(:state, state) if synthetic.respond_to?(:state)
    end

    def update_state_from_fatigue
      new_state = (synthetic.fatigue.to_i >= 60) ? "tired" : "online"
      update_state(new_state)
    end

    def blocked_response(reason)
      Rails.logger.warn { "[Synthetic::Pipeline] Message blocked for #{synthetic.name}: #{reason}" }
      nil
    end
  end
end
