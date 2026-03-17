module PrefrontalCortex
  class TurnProcessor
    def initialize(llm_provider: nil)
      @llm_provider = llm_provider
    end

    def process(agent:, inbound_message:, memories:, conversation: nil)
      system_prompt = build_system_prompt(agent)
      context = build_context(memories, inbound_message, conversation)

      reply_text = @llm_provider.complete(system_prompt: system_prompt, context: context)

      reply = Message.create!(
        from: agent,
        to: inbound_message.from,
        conversation: inbound_message.conversation
      )
      reply.parts.create!(content_type: "text/markdown", body: reply_text, position: 0)

      reply
    end

    private

    def build_system_prompt(agent)
      emotion_summary = agent.emotion_parameters
        .map { |k, v| "#{k}: #{v}" }
        .join(", ")

      parts = []
      parts << agent.description if agent.description.present?
      parts << "Agent class: #{agent.agent_class}"
      parts << "Emotional state: #{emotion_summary}"
      parts.join("\n")
    end

    def build_context(memories, inbound_message, conversation)
      parts = []

      unless memories.empty?
        parts << "Relevant memories:"
        memories.each { |m| parts << "- #{m.content}" }
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
