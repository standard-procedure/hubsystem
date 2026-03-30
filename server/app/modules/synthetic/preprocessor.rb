# frozen_string_literal: true

class Synthetic
  class Preprocessor < Literal::Data
    prop :synthetic, Synthetic

    class Result < Literal::Data
      prop :blocked, _Boolean
      prop :reason, String
    end

    def process(message)
      raise ArgumentError unless Message === message
      threat, _ = Concurrent.run(
        -> { ThreatAssessor.new(synthetic: @synthetic).process(message) },
        -> { EmotionalProcessor.new(synthetic: @synthetic).process_incoming(message) }
      )
      Result.new(
        blocked: threat.status == :blocked,
        reason: threat.reason
      )
    end
  end
end
