# frozen_string_literal: true

class WriteDocumentTool < RubyLLM::Tool
  description "Create or update a public document. Documents are visible to all users."

  param :title, type: "string", desc: "Document title", required: true
  param :content, type: "string", desc: "Document content", required: true
  param :tags, type: "string", desc: "Comma-separated tags for categorisation", required: true

  def initialize(synthetic)
    @synthetic = synthetic
    super()
  end

  def execute(title:, content:, tags:)
    tag_list = tags.split(",").map(&:strip).reject(&:empty?)
    document = Document.create!(author: @synthetic, title: title, content: content, tags: tag_list)
    "Document created: [#{document.id}] #{document.title} [tags: #{tag_list.join(", ")}]"
  end
end
