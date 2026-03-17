module Amygdala
  class EmotionUpdater
    HOSTILE_KEYWORDS = %w[hate kill destroy attack threat].freeze

    def update(agent, message, direction: :inbound)
      params = agent.emotion_parameters.dup

      case direction
      when :do_not_process
        params["anxious"] = clamp(params["anxious"].to_i + 10)
        params["irritated"] = clamp(params["irritated"].to_i + 5)
      when :inbound
        text = message_text(message)
        if hostile?(text)
          params["anxious"] = clamp(params["anxious"].to_i + 5)
          params["happy"] = clamp(params["happy"].to_i - 3)
        end
        params["exhausted"] = clamp(params["exhausted"].to_i + 2)
      when :outbound
        params["happy"] = clamp(params["happy"].to_i + 1)
      end

      agent.update!(emotion_parameters: params)
    end

    private

    def hostile?(text)
      HOSTILE_KEYWORDS.any? { |kw| text.downcase.include?(kw) }
    end

    def message_text(message)
      message.parts.map(&:body).join(" ")
    end

    def clamp(value)
      [[value, 0].max, 100].min
    end
  end
end
