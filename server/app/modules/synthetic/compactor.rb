# frozen_string_literal: true

class Synthetic
  class Compactor < BaseModule
    RECENT_MESSAGE_COUNT = 20

    SYSTEM_PROMPT = <<~PROMPT
      You are a memory consolidation module for an AI agent named %{name}. The agent is going to sleep and needs its conversation history compressed.

      Given the following conversation history, produce a JSON response with:
      1. A narrative summary of what happened (conversations, decisions, outcomes)
      2. Key facts worth remembering permanently
      3. The agent's emotional context at the end of this period

      Respond with JSON only:
      {
        "summary": "Narrative summary of interactions and outcomes...",
        "facts": [
          {"content": "Important fact to remember", "tags": ["topic1", "topic2"]}
        ],
        "emotional_context": "How the agent was feeling and why..."
      }
    PROMPT

    def compact!
      @synthetic.update_column(:state, "offline") if @synthetic.respond_to?(:state)
      context = @synthetic.ensure_llm_context
      messages = context.llm_context_messages.order(:created_at)
      return if messages.count <= RECENT_MESSAGE_COUNT

      compaction_zone = messages.offset(0).limit(messages.count - RECENT_MESSAGE_COUNT)
      history_text = build_history_text(compaction_zone)

      # Summarise via low-cost LLM
      prompt = format(SYSTEM_PROMPT, name: @synthetic.name)
      response = evaluate(prompt, history_text)
      parsed = parse_response(response)

      # Persist extracted facts as memories
      persist_memories(parsed["facts"])

      # Replace old messages with summary
      summary_text = "[Context summary from earlier interactions]\n\n#{parsed["summary"]}"
      summary_text += "\n\n[Emotional context: #{parsed["emotional_context"]}]" if parsed["emotional_context"].present?

      compaction_zone.destroy_all
      context.llm_context_messages.create!(
        role: "assistant",
        content: summary_text,
        llm_context: context
      )

      # Recalculate fatigue
      CapacityEvaluator.new(@synthetic).process

      Rails.logger.info { "[Synthetic::Compactor] #{@synthetic.name} completed sleep cycle — #{compaction_zone.count} messages compacted" }
    end

    private

    def build_history_text(messages)
      messages.map do |m|
        "#{m.role}: #{m.content}"
      end.join("\n\n")
    end

    def parse_response(response)
      JSON.parse(response)
    rescue JSON::ParserError
      {"summary" => response, "facts" => [], "emotional_context" => ""}
    end

    def persist_memories(facts)
      return unless facts.is_a?(Array)

      facts.each do |fact|
        tags = (fact["tags"] || []) + ["compaction"]
        @synthetic.memories.create!(content: fact["content"], tags: tags)
      end
    end
  end
end
