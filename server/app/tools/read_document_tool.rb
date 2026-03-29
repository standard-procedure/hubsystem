# frozen_string_literal: true

class ReadDocumentTool < SyntheticTool
  description "Search public documents by tag or text query. Documents are visible to all users."

  param :query, type: "string", desc: "Text to search for in document title or content", required: false
  param :tag, type: "string", desc: "Tag to filter documents by", required: false
  param :limit, type: "integer", desc: "Maximum number of results (default 10)", required: false

  def execute(query: nil, tag: nil, limit: 10)
    capped_limit = [limit, 50].min

    if query.present?
      results = semantic_search(query, tag, capped_limit)
    else
      scope = Document.recent
      scope = scope.tagged_with(tag) if tag.present?
      results = scope.limit(capped_limit)
    end

    return "No documents found." if results.empty?

    results.map { |d| "- [#{d.id}] #{d.title}: #{d.content.truncate(200)} [tags: #{d.tags.join(", ")}]" }.join("\n")
  end

  private

  def semantic_search(query, tag, limit)
    results = Document.semantic_search(query, limit: limit)
    results = results.tagged_with(tag) if tag.present?
    return results if results.any?

    text_search(query, tag, limit)
  rescue => e
    Rails.logger.warn("Semantic search failed, falling back to text search: #{e.message}")
    text_search(query, tag, limit)
  end

  def text_search(query, tag, limit)
    scope = Document.recent
    scope = scope.tagged_with(tag) if tag.present?
    scope.search(query).limit(limit)
  end
end
