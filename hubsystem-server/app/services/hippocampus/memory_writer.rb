module Hippocampus
  class MemoryWriter
    def initialize(embedding_provider: nil)
      @embedding_provider = embedding_provider
    end

    def write(participant:, content:, scope: :personal, metadata: {})
      embedding = @embedding_provider.embed(content)
      scope_str = scope.to_s

      attrs = { participant: participant, content: content, scope: scope_str }

      Memory.find_or_create_by(attrs) do |memory|
        memory.agent_class = participant.agent_class if participant.respond_to?(:agent_class)
        memory.metadata = metadata
        memory.embedding = embedding
      end
    end
  end
end
