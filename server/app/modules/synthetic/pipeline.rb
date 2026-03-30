# frozen_string_literal: true

class Synthetic
  class Pipeline < Literal::Data
    prop :synthetic, Synthetic

    def process(message)
      raise ArgumentError unless Message === message
      update_state(:busy)

      # 1. Pre-process: threat assessment + incoming emotion (concurrent)
      preprocess = Preprocessor.new(synthetic: @synthetic).process(message)
      if preprocess.blocked
        update_state_from_fatigue
        return blocked_response(preprocess.reason)
      end

      # 2. Process: LLM generates a response
      context = synthetic.ensure_llm_context
      config = llm_config(synthetic.llm_tier)
      context.with_model(config[:model])
      context.with_instructions(synthetic.system_prompt)
      context.with_tools(*tools)
      response_text = context.ask(synthetic.prompt_for(message)).content

      # 3. Govern: check the response is appropriate
      governance = Governor.new(synthetic: @synthetic).process(response_text)
      response_text = Governor::REFUSAL_MESSAGE unless governance.approved

      # 4. Post-process: memory + outgoing emotion (concurrent) + capacity
      Postprocessor.new(synthetic: @synthetic).process(response_text)

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

    def llm_config(tier)
      Rails.application.config.llm_models[tier.to_sym]
    end

    def update_state(state)
      synthetic.user&.update_column(:state, state)
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
