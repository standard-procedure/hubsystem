module Brainstem
  class ExhaustionMonitor
    EXHAUSTION_THRESHOLD = 80

    def check(agent)
      return false unless agent.emotion_parameters["exhausted"].to_i >= EXHAUSTION_THRESHOLD

      agent.update!(state: "napping")
      Brainstem::CompactionJob.perform_later(agent.id)
      true
    end
  end
end
