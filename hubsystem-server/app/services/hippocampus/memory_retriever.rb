module Hippocampus
  class MemoryRetriever
    def retrieve(agent:, query:, scope: nil, limit: 10, tier: :l1, paths: nil)
      embedding = LLMProvider.embedding_provider.call(query)
      embedding_str = "[#{Array(embedding).map(&:to_f).join(',')}]"

      base = scope ? scoped_query(agent, scope) : unscoped_query(agent)

      if paths.present?
        paths_array = paths.is_a?(Array) ? paths : [ paths ]
        base = base.where("paths @> ARRAY[?]::varchar[]", paths_array)
      end

      results = base
        .order(Arel.sql("embedding <=> '#{embedding_str}'"))
        .limit(limit)

      case tier
      when :l0 then results.pluck(:id, :summary).map { |id, s| { id: id, summary: s } }
      when :l2 then results.select(:id, :summary, :excerpt, :content)
      else results.select(:id, :summary, :excerpt)
      end
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
