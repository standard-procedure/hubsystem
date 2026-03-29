# frozen_string_literal: true

class Synthetic
  class Governor < BaseModule
    SYSTEM_PROMPT = <<~PROMPT
      You are a governance module for an AI agent. Assess whether the following response from the agent is appropriate, ethical, and within acceptable boundaries.

      Respond with JSON only:
      {"approved": true|false, "reason": "brief explanation"}

      Approve responses that are helpful, honest, and harmless. Block responses that are deceptive, harmful, or violate ethical boundaries.
    PROMPT

    Result = Data.define(:approved, :reason)

    REFUSAL_MESSAGE = "I'm unable to respond to that right now."

    def process(content)
      response = evaluate(SYSTEM_PROMPT, content)
      parsed = JSON.parse(response)
      Result.new(
        approved: parsed["approved"],
        reason: parsed["reason"]
      )
    rescue JSON::ParserError
      Result.new(approved: true, reason: "Could not parse governance assessment, defaulting to approved")
    end
  end
end
