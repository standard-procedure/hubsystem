# frozen_string_literal: true

class Synthetic
  class Postprocessor < Literal::Data
    prop :synthetic, Synthetic
    def process(response_text)
      raise ArgumentError unless String === response_text
      Concurrent.run(
        -> { MemoryProcessor.new(synthetic: @synthetic).process(response_text) },
        -> { EmotionalProcessor.new(synthetic: @synthetic).process_outgoing(response_text) }
      )

      capacity = CapacityEvaluator.new(synthetic: @synthetic).process
      Compactor.new(synthetic: @synthetic).compact! if capacity.needs_compaction
    end
  end
end
