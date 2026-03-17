module PrefrontalCortex
  class TurnProcessor
    def process(agent:, inbound_message:, memories:, conversation: nil)
      system_prompt = build_system_prompt(agent, inbound_message)
      context = build_context(memories, inbound_message, conversation)

      llm = LLMProvider.for_role(:main_turn)
      reply_text = llm.call(system_prompt, context)

      reply = Message.create!(
        from: agent,
        to: inbound_message.from,
        conversation: inbound_message.conversation
      )
      reply.parts.create!(content_type: "text/markdown", body: reply_text, position: 0)

      reply
    end

    private

    def build_system_prompt(agent, inbound_message)
      emotion_summary = agent.emotion_parameters
        .map { |k, v| "#{k}: #{v}" }
        .join(", ")

      parts = []
      parts << agent.description if agent.description.present?
      parts << "Agent class: #{agent.agent_class}"
      parts << "Emotional state: #{emotion_summary}"

      message_text = inbound_message.parts.map(&:body).join(" ")
      l0_memories = Hippocampus::MemoryRetriever.new.retrieve(
        agent: agent, query: message_text, limit: 20, tier: :l0
      )
      unless l0_memories.empty?
        parts << "\nMemory summaries:"
        l0_memories.each { |m| parts << "- #{m[:summary]}" }
      end

      parts.join("\n")
    end

    def build_context(memories, inbound_message, conversation)
      parts = []

      unless memories.empty?
        parts << "Relevant memories:"
        memories.each do |m|
          excerpt = m.respond_to?(:excerpt) ? m.excerpt : m[:excerpt]
          content = excerpt.presence || (m.respond_to?(:content) ? m.content : m[:content])
          parts << "- #{content}" if content.present?
        end
        parts << ""
      end

      if conversation
        recent = conversation.messages
          .includes(:parts, :from)
          .order(created_at: :desc)
          .limit(10)
          .reverse

        recent.each do |msg|
          next if msg.id == inbound_message.id
          msg_text = msg.parts.map(&:body).join(" ")
          parts << "[#{msg.from.name}]: #{msg_text}"
        end
        parts << "" unless parts.empty?
      end

      inbound_text = inbound_message.parts.map(&:body).join("\n")
      parts << "Inbound message: #{inbound_text}"

      parts.join("\n")
    end
  end
end
