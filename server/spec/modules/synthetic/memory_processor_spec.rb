# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synthetic::MemoryProcessor, type: :module do
  fixtures :users, :humans, :synthetics, :synthetic_classes

  let(:bishop) { users(:bishop) }
  let(:processor) { described_class.new(bishop) }

  describe "#process" do
    it "extracts and persists memories" do
      stub_llm_response('{"memories": [{"content": "Alice prefers morning meetings", "tags": ["alice", "preferences"]}]}')

      expect {
        result = processor.process("Alice said she likes morning meetings.")
        expect(result.memories.size).to eq(1)
      }.to change(Synthetic::Memory, :count).by(1)

      memory = bishop.memories.last
      expect(memory.content).to eq("Alice prefers morning meetings")
      expect(memory.tags).to include("alice")
    end

    it "persists multiple memories" do
      stub_llm_response('{"memories": [{"content": "Fact one", "tags": ["a"]}, {"content": "Fact two", "tags": ["b"]}]}')

      expect {
        processor.process("Lots of information here.")
      }.to change(Synthetic::Memory, :count).by(2)
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
