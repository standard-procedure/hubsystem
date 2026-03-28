# frozen_string_literal: true

module Synthetic
  class Pipeline
    attr_reader :synthetic

    def initialize(synthetic)
      @synthetic = synthetic
      @threat_assessor = ThreatAssessor.new(synthetic)
      @emotional_processor = EmotionalProcessor.new(synthetic)
      @governor = Governor.new(synthetic)
      @memory_processor = MemoryProcessor.new(synthetic)
      @capacity_evaluator = CapacityEvaluator.new(synthetic)
    end

    def process(message)
      # 1. Threat assessment
      threat = @threat_assessor.process(message)
      return blocked_response(threat.reason) if threat.status == :blocked

      # 2. Emotional processing of incoming message
      @emotional_processor.process_incoming(message)

      # 3. LLM processes the message (with tools available)
      context = synthetic.ensure_llm_context
      context.with_tools(*tools)
      response = context.ask(message)
      response_text = response.content

      # 4. Governor checks the response
      governance = @governor.process(response_text)
      unless governance.approved
        response_text = Governor::REFUSAL_MESSAGE
      end

      # 5. Memory processing
      @memory_processor.process(response_text)

      # 6. Emotional processing of outgoing response
      @emotional_processor.process_outgoing(response_text)

      # 7. Capacity evaluation
      @capacity_evaluator.process

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
        ListTasksTool.new(synthetic)
      ]
    end

    def blocked_response(reason)
      Rails.logger.warn { "[Synthetic::Pipeline] Message blocked for #{synthetic.name}: #{reason}" }
      nil
    end
  end
end
