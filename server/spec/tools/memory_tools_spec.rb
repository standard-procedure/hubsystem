# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Memory tools", type: :model do
  fixtures :users, :synthetic_memories

  let(:bishop) { users(:bishop) }

  describe ReadMemoryTool do
    let(:tool) { described_class.new(bishop) }

    it "searches by tag" do
      result = tool.execute(tag: "alice")
      expect(result).to include("Alice likes mornings")
      expect(result).not_to include("deadline")
    end

    it "searches by query" do
      result = tool.execute(query: "deadline")
      expect(result).to include("Project deadline Friday")
    end

    it "returns no memories message when empty" do
      result = tool.execute(tag: "nonexistent")
      expect(result).to eq("No memories found.")
    end
  end

  describe WriteMemoryTool do
    let(:tool) { described_class.new(bishop) }

    it "creates a memory with tags" do
      expect {
        result = tool.execute(content: "Bob is helpful", tags: "bob, team")
        expect(result).to include("Memory saved")
      }.to change(Synthetic::Memory, :count).by(1)

      memory = bishop.memories.last
      expect(memory.content).to eq("Bob is helpful")
      expect(memory.tags).to eq(["bob", "team"])
    end
  end
end
