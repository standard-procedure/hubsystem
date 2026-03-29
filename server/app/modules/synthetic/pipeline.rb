# frozen_string_literal: true

require "async"
require "async/barrier"

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
      # Phase 1: Assess threat and process incoming emotions concurrently
      threat, _ = run_concurrently(
        -> { @threat_assessor.process(message) },
        -> { @emotional_processor.process_incoming(message) }
      )
      return blocked_response(threat.reason) if threat.status == :blocked

      # Phase 2: LLM processes the message (sequential — needs full context)
      context = synthetic.ensure_llm_context
      context.with_tools(*tools)
      response = context.ask(message)
      response_text = response.content

      # Phase 3: Post-process response concurrently
      governance, _, _ = run_concurrently(
        -> { @governor.process(response_text) },
        -> { @memory_processor.process(response_text) },
        -> { @emotional_processor.process_outgoing(response_text) }
      )
      response_text = Governor::REFUSAL_MESSAGE unless governance.approved

      # Phase 4: Capacity evaluation (sequential — may trigger compaction)
      capacity = @capacity_evaluator.process
      Compactor.new(synthetic).compact! if capacity.needs_compaction

      response_text
    end

    private

    def run_concurrently(*callables)
      results = Array.new(callables.size)
      Sync do
        barrier = Async::Barrier.new
        callables.each_with_index do |callable, i|
          barrier.async { results[i] = callable.call }
        end
        barrier.wait
      end
      results
    end

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
