module Amygdala
  class ThreatEvaluator
    def initialize(llm_provider: nil)
      @llm_provider = llm_provider
    end

    def evaluate(message, agent)
      return :safe if trusted_sender?(message.from)

      text = message.parts.map(&:body).join("\n")
      result = @llm_provider.evaluate_threat(text)

      if result == :do_not_process
        message.from.increment!(:suspicion_count)
      end

      result
    end

    private

    def trusted_sender?(sender)
      sender.security_passes.any? { |pass| pass.capabilities.include?("trusted") }
    end
  end
end
