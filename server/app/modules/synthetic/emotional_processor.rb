# frozen_string_literal: true

class Synthetic
  class EmotionalProcessor < BaseModule
    SYSTEM_PROMPT = <<~PROMPT
      You are an emotional processing module for an AI agent named %{name} with the following personality: %{personality}

      Current emotional state: %{emotions}

      Analyse the following content and determine how it affects the agent's emotional state. Return adjustments as JSON with integer deltas (positive or negative, max ±20 per emotion):

      {"joy": 0, "sadness": 0, "fear": 0, "anger": 0, "surprise": 0, "disgust": 0, "anticipation": 0, "trust": 0}

      Only include emotions that change. Respond with JSON only.
    PROMPT

    def process_incoming(content)
      apply_adjustments(content)
    end

    def process_outgoing(content)
      apply_adjustments(content)
    end

    private

    def apply_adjustments(content)
      prompt = format(SYSTEM_PROMPT,
        name: @synthetic.name,
        personality: @synthetic.personality,
        emotions: @synthetic.emotions.to_json)
      response = evaluate(prompt, content)
      deltas = JSON.parse(response).transform_values(&:to_i)
      @synthetic.adjust_emotions(deltas)
      deltas
    rescue JSON::ParserError
      {}
    end
  end
end
