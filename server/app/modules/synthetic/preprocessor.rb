# frozen_string_literal: true

module Synthetic
  class Preprocessor
    Result = Data.define(:blocked, :reason)

    def initialize(synthetic)
      @threat_assessor = ThreatAssessor.new(synthetic)
      @emotional_processor = EmotionalProcessor.new(synthetic)
    end

    def process(message)
      threat, _ = Concurrent.run(
        -> { @threat_assessor.process(message) },
        -> { @emotional_processor.process_incoming(message) }
      )
      Result.new(
        blocked: threat.status == :blocked,
        reason: threat.reason
      )
    end
  end
end
