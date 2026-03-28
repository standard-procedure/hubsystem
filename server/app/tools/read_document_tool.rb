# frozen_string_literal: true

class ReadDocumentTool < RubyLLM::Tool
  description "Search public documents by tag or text query. Documents are visible to all users."

  param :query, type: "string", desc: "Text to search for in document title or content", required: false
  param :tag, type: "string", desc: "Tag to filter documents by", required: false
  param :limit, type: "integer", desc: "Maximum number of results (default 10)", required: false

  def initialize(synthetic = nil)
    super()
  end

  def execute(query: nil, tag: nil, limit: 10)
    scope = Document.recent
    scope = scope.tagged_with(tag) if tag.present?
    scope = scope.search(query) if query.present?
    results = scope.limit([limit, 50].min)

    return "No documents found." if results.empty?

    results.map { |d| "- [#{d.id}] #{d.title}: #{d.content.truncate(200)} [tags: #{d.tags.join(", ")}]" }.join("\n")
  end
end
