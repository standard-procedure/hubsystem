# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synthetic::MemoryProcessor, type: :module do
  fixtures :users

  let(:bishop) { users(:bishop) }
  let(:processor) { described_class.new(bishop) }

  describe "#process" do
    it "extracts memories from content" do
      stub_llm_response('{"memories": [{"content": "Alice prefers morning meetings", "tags": ["alice", "preferences"]}]}')
      result = processor.process("Alice said she likes morning meetings.")
      expect(result.memories.size).to eq(1)
      expect(result.memories.first["content"]).to eq("Alice prefers morning meetings")
      expect(result.memories.first["tags"]).to include("alice")
    end

    it "returns empty memories when nothing to remember" do
      stub_llm_response('{"memories": []}')
      result = processor.process("Hello")
      expect(result.memories).to be_empty
    end

    it "returns empty memories on parse error" do
      stub_llm_response("Not JSON")
      result = processor.process("Hello")
      expect(result.memories).to be_empty
    end
  end
end
