# frozen_string_literal: true

class WriteMemoryTool < RubyLLM::Tool
  description "Store a private memory for future reference. Memories are only visible to you."

  param :content, type: "string", desc: "The fact or observation to remember", required: true
  param :tags, type: "string", desc: "Comma-separated tags for categorisation", required: true

  def initialize(synthetic)
    @synthetic = synthetic
    super()
  end

  def execute(content:, tags:)
    tag_list = tags.split(",").map(&:strip).reject(&:empty?)
    memory = @synthetic.memories.create!(content: content, tags: tag_list)
    "Memory saved: #{memory.content} [tags: #{tag_list.join(", ")}]"
  end
end
