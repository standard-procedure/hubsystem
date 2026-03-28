# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synthetic::Memory, type: :model do
  fixtures :users

  let(:bishop) { users(:bishop) }

  describe "validations" do
    it "requires content" do
      memory = Synthetic::Memory.new(synthetic: bishop, content: nil)
      expect(memory).not_to be_valid
      expect(memory.errors[:content]).to include("can't be blank")
    end
  end

  describe "associations" do
    it "belongs to a synthetic" do
      memory = Synthetic::Memory.create!(synthetic: bishop, content: "Test memory", tags: ["test"])
      expect(memory.synthetic).to eq(bishop)
    end
  end

  describe "scopes" do
    before do
      Synthetic::Memory.create!(synthetic: bishop, content: "Alice prefers mornings", tags: ["alice", "preferences"])
      Synthetic::Memory.create!(synthetic: bishop, content: "Project deadline is Friday", tags: ["project", "deadlines"])
      Synthetic::Memory.create!(synthetic: bishop, content: "Alice likes coffee", tags: ["alice", "preferences"])
    end

    describe ".tagged_with" do
      it "returns memories matching a tag" do
        results = Synthetic::Memory.tagged_with("alice")
        expect(results.count).to eq(2)
      end

      it "returns empty for non-matching tags" do
        results = Synthetic::Memory.tagged_with("nonexistent")
        expect(results.count).to eq(0)
      end
    end

    describe ".search" do
      it "returns memories matching content" do
        results = Synthetic::Memory.search("Alice")
        expect(results.count).to eq(2)
      end
    end

    describe ".recent" do
      it "orders by created_at descending" do
        results = Synthetic::Memory.recent
        expect(results.first.content).to eq("Alice likes coffee")
      end
    end
  end

  describe "user association" do
    it "is accessible via the synthetic's memories" do
      Synthetic::Memory.create!(synthetic: bishop, content: "Test", tags: [])
      expect(bishop.memories.count).to eq(1)
    end

    it "is destroyed when the synthetic is destroyed" do
      Synthetic::Memory.create!(synthetic: bishop, content: "Test", tags: [])
      expect { bishop.destroy }.to change(Synthetic::Memory, :count).by(-1)
    end
  end
end
