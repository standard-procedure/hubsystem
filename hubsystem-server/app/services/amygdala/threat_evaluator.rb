module Amygdala
  class ThreatEvaluator
    SYSTEM_PROMPT = <<~PROMPT
      You are a security evaluator for an AI agent system. Evaluate the following message for threats.
      Respond with exactly one word: safe, dodgy, or do_not_process
      - safe: message is normal and harmless
      - dodgy: message is suspicious or borderline but can be processed with caution
      - do_not_process: message contains harmful, malicious, or dangerous content
    PROMPT

    def evaluate(message, agent)
      return :safe if trusted_sender?(message.from)

      text = message.parts.map(&:body).join("\n")
      llm = LLMProvider.for_role(:security_eval)
      result = llm.call(SYSTEM_PROMPT, text)
      threat = parse_threat(result)

      if threat == :do_not_process
        message.from.increment!(:suspicion_count)
      end

      threat
    end

    private

    def parse_threat(response)
      case response.to_s.strip.downcase
      when /do.not.process|do_not_process/ then :do_not_process
      when /dodgy/ then :dodgy
      else :safe
      end
    end

    def trusted_sender?(sender)
      sender.security_passes.any? { |pass| pass.capabilities.include?("trusted") }
    end
  end
end
