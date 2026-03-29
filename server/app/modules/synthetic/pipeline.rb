# frozen_string_literal: true

module Synthetic
  class Pipeline
    attr_reader :synthetic

    def initialize(synthetic)
      @synthetic = synthetic
      @preprocessor = Preprocessor.new(synthetic)
      @governor = Governor.new(synthetic)
      @postprocessor = Postprocessor.new(synthetic)
    end

    def process(message)
      # 1. Pre-process: threat assessment + incoming emotion (concurrent)
      preprocess = @preprocessor.process(message)
      return blocked_response(preprocess.reason) if preprocess.blocked

      # 2. Process: LLM generates a response
      context = synthetic.ensure_llm_context
      context.with_tools(*tools)
      response_text = context.ask(message).content

      # 3. Govern: check the response is appropriate
      governance = @governor.process(response_text)
      response_text = Governor::REFUSAL_MESSAGE unless governance.approved

      # 4. Post-process: memory + outgoing emotion (concurrent) + capacity
      @postprocessor.process(response_text)

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
        RunCommandTool.new(synthetic)
      ]
    end

    def blocked_response(reason)
      Rails.logger.warn { "[Synthetic::Pipeline] Message blocked for #{synthetic.name}: #{reason}" }
      nil
    end
  end
end
