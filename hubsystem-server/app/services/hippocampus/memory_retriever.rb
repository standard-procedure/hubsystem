module Hippocampus
  class MemoryRetriever
    def initialize(embedding_provider: nil)
      @embedding_provider = embedding_provider
    end

    def retrieve(agent:, query:, scope: nil, limit: 10)
      embedding = @embedding_provider.embed(query)
      embedding_str = "[#{Array(embedding).map(&:to_f).join(',')}]"

      base = scope ? scoped_query(agent, scope) : unscoped_query(agent)

      base
        .order(Arel.sql("embedding <=> '#{embedding_str}'"))
        .limit(limit)
    end

    private

    def unscoped_query(agent)
      personal = Memory.where(scope: "personal", participant: agent)
      class_mem = Memory.where(scope: "class_memory", agent_class: agent.agent_class)

      result = personal.or(class_mem)

      if can_access_knowledge_base?(agent)
        result = result.or(Memory.where(scope: "knowledge_base"))
      end

      result
    end

    def scoped_query(agent, scope)
      case scope.to_s
      when "personal"
        Memory.where(scope: "personal", participant: agent)
      when "class_memory"
        Memory.where(scope: "class_memory", agent_class: agent.agent_class)
      when "knowledge_base"
        can_access_knowledge_base?(agent) ? Memory.where(scope: "knowledge_base") : Memory.none
      else
        Memory.none
      end
    end

    def can_access_knowledge_base?(agent)
      agent.security_passes.any? { |pass| pass.capabilities.include?("knowledge_base") }
    end
  end
end
