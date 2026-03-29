# frozen_string_literal: true

class ReadMemoryTool < SyntheticTool
  description "Search your private memories by tag or text query. Returns matching memories."

  param :query, type: "string", desc: "Text to search for in memory content", required: false
  param :tag, type: "string", desc: "Tag to filter memories by", required: false
  param :limit, type: "integer", desc: "Maximum number of results (default 10)", required: false

  def execute(query: nil, tag: nil, limit: 10)
    capped_limit = [limit, 50].min

    if query.present?
      results = semantic_search(query, tag, capped_limit)
    else
      scope = @synthetic.memories.recent
      scope = scope.tagged_with(tag) if tag.present?
      results = scope.limit(capped_limit)
    end

    return "No memories found." if results.empty?

    results.map { |m| "- #{m.content} [tags: #{m.tags.join(", ")}]" }.join("\n")
  end

  private

  def semantic_search(query, tag, limit)
    results = Synthetic::Memory.semantic_search(query, limit: limit)
      .where(synthetic: @synthetic)
    results = results.tagged_with(tag) if tag.present?
    return results if results.any?

    text_search(query, tag, limit)
  rescue => e
    Rails.logger.warn("Semantic search failed, falling back to text search: #{e.message}")
    text_search(query, tag, limit)
  end

  def text_search(query, tag, limit)
    scope = @synthetic.memories.recent
    scope = scope.tagged_with(tag) if tag.present?
    scope.search(query).limit(limit)
  end
end
