module Hippocampus
  class MemoryWriter
    def write(participant:, content:, scope: :personal, metadata: {}, summary: nil, excerpt: nil)
      return if Memory.exists?(participant: participant, content: content)

      summary, excerpt = generate_tiers(content, summary, excerpt)
      paths = generate_paths(content)

      embed_text = excerpt.presence || content
      embedding = LLMProvider.embedding_provider.call(embed_text)

      Memory.create!(
        participant: participant,
        scope: scope.to_s,
        summary: summary,
        excerpt: excerpt,
        content: content,
        embedding: embedding,
        metadata: metadata,
        paths: paths,
        agent_class: participant.respond_to?(:agent_class) ? participant.agent_class : nil
      )
    end

    private

    def generate_tiers(content, summary, excerpt)
      llm = LLMProvider.for_role(:path_generation)

      summary ||= llm.call(
        "Summarise the following in one short sentence (max 15 words):",
        content
      ).strip

      excerpt ||= llm.call(
        "Summarise the following in one short paragraph (3-5 sentences):",
        content
      ).strip

      [ summary, excerpt ]
    end

    def generate_paths(content)
      paths = []

      paths << Date.today.strftime("%Y/%m/%d")
      paths << Date.today.strftime("%Y/%m")
      paths << Date.today.strftime("%Y")

      llm = LLMProvider.for_role(:path_generation)
      raw = llm.call(
        'Extract 2-5 path tags from this content. Format: one per line, hierarchical e.g. "Conversations/George" or "Projects/HubSystem" or "Topics/Architecture". Only output the paths, nothing else.',
        content
      )

      llm_paths = raw.strip.split("\n").map(&:strip).reject(&:empty?).first(5)
      paths.concat(llm_paths)
      paths.uniq
    end
  end
end
