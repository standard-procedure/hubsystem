# frozen_string_literal: true

module Synthetic
  class Postprocessor
    def initialize(synthetic)
      @synthetic = synthetic
      @memory_processor = MemoryProcessor.new(synthetic)
      @emotional_processor = EmotionalProcessor.new(synthetic)
      @capacity_evaluator = CapacityEvaluator.new(synthetic)
    end

    def process(response_text)
      Concurrent.run(
        -> { @memory_processor.process(response_text) },
        -> { @emotional_processor.process_outgoing(response_text) }
      )

      capacity = @capacity_evaluator.process
      Compactor.new(@synthetic).compact! if capacity.needs_compaction
    end
  end
end
