# frozen_string_literal: true

require "rails_helper"

RSpec.describe User::Synthetic, type: :model do
  fixtures :users

  let(:bishop) { users(:bishop) }

  it "is a User subclass" do
    expect(User::Synthetic.superclass).to eq(User)
  end

  it "loads synthetic users from fixtures" do
    expect(bishop).to be_a(User::Synthetic)
  end

  describe "emotions" do
    it "has default emotional state" do
      expect(bishop.emotions).to include("joy" => 50, "fear" => 10, "trust" => 50)
    end

    it "adjusts emotions with deltas clamped to 0-100" do
      bishop.adjust_emotions("joy" => 60, "fear" => -20)
      expect(bishop.emotions["joy"]).to eq(100)
      expect(bishop.emotions["fear"]).to eq(0)
    end

    it "ignores unknown emotions" do
      expect { bishop.adjust_emotions(confusion: 50) }.not_to raise_error
    end
  end

  describe "fatigue" do
    it "defaults to 0" do
      expect(bishop.fatigue).to eq(0)
    end
  end

  describe "llm_context" do
    it "can create an llm_context" do
      context = bishop.ensure_llm_context
      expect(context).to be_a(LlmContext)
      expect(context).to be_persisted
      expect(context.user).to eq(bishop)
    end

    it "returns existing context on subsequent calls" do
      first = bishop.ensure_llm_context
      second = bishop.ensure_llm_context
      expect(first.id).to eq(second.id)
    end
  end
end
