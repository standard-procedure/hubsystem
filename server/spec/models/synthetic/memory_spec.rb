# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synthetic::Memory, type: :model do
  fixtures :users, :synthetic_memories

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
      expect(synthetic_memories(:alice_mornings).synthetic).to eq(bishop)
    end
  end

  describe "scopes" do
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
        synthetic_memories(:alice_coffee).update_column(:created_at, 1.minute.from_now)
        results = Synthetic::Memory.recent
        expect(results.first.content).to eq("Alice likes coffee")
      end
    end
  end

  describe "user association" do
    it "is accessible via the synthetic's memories" do
      expect(bishop.memories.count).to eq(3)
    end

    it "is destroyed when the synthetic is destroyed" do
      expect { bishop.destroy }.to change(Synthetic::Memory, :count).by(-3)
    end
  end
end
