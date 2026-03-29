# frozen_string_literal: true

class Synthetic
  class MemoryProcessor < BaseModule
    SYSTEM_PROMPT = <<~PROMPT
      You are a memory processing module for an AI agent. Analyse the following content and identify any facts, preferences, or information worth remembering for future interactions.

      Respond with JSON only:
      {"memories": [{"content": "what to remember", "tags": ["topic1", "topic2"]}]}

      Return an empty memories array if nothing is worth remembering.
    PROMPT

    Result = Data.define(:memories)

    def process(content)
      response = evaluate(SYSTEM_PROMPT, content)
      parsed = JSON.parse(response)
      memories = parsed["memories"] || []

      memories.each do |memory|
        @synthetic.memories.create!(
          content: memory["content"],
          tags: memory["tags"] || []
        )
      end

      Result.new(memories: memories)
    rescue JSON::ParserError
      Result.new(memories: [])
    end
  end
end
