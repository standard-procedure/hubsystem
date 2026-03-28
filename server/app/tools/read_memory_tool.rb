# frozen_string_literal: true

class ReadMemoryTool < RubyLLM::Tool
  description "Search your private memories by tag or text query. Returns matching memories."

  param :query, type: "string", desc: "Text to search for in memory content", required: false
  param :tag, type: "string", desc: "Tag to filter memories by", required: false
  param :limit, type: "integer", desc: "Maximum number of results (default 10)", required: false

  def initialize(synthetic)
    @synthetic = synthetic
    super()
  end

  def execute(query: nil, tag: nil, limit: 10)
    scope = @synthetic.memories.recent
    scope = scope.tagged_with(tag) if tag.present?
    scope = scope.search(query) if query.present?
    results = scope.limit([limit, 50].min)

    return "No memories found." if results.empty?

    results.map { |m| "- #{m.content} [tags: #{m.tags.join(", ")}]" }.join("\n")
  end
end
