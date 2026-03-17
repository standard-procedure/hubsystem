module Hippocampus
  class ClassMemoryPromoter
    def initialize(embedding_provider: nil)
      @embedding_provider = embedding_provider
    end

    def evaluate(memory, confidence:)
      return nil unless confidence >= 0.8
      return nil unless memory.participant.is_a?(AgentParticipant)

      agent = memory.participant

      Memory.find_or_create_by(
        scope: "class_memory",
        agent_class: agent.agent_class,
        content: memory.content
      ) do |m|
        m.participant = agent
        m.metadata = memory.metadata
        m.embedding = memory.embedding
      end
    end
  end
end
