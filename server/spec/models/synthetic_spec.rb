# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synthetic, type: :model do
  fixtures :users, :humans, :synthetics, :synthetic_classes

  let(:bishop) { users(:bishop) }
  let(:bishop_synthetic) { synthetics(:bishop_synthetic) }

  it "has a user via delegated type" do
    expect(bishop).to be_synthetic
    expect(bishop.role).to be_a(Synthetic)
  end

  describe "emotions" do
    it "has default emotional state" do
      expect(bishop_synthetic.emotions).to include("joy" => 50, "fear" => 10, "trust" => 50)
    end

    it "adjusts emotions with deltas clamped to 0-100" do
      bishop_synthetic.adjust_emotions("joy" => 60, "fear" => -20)
      expect(bishop_synthetic.emotions["joy"]).to eq(100)
      expect(bishop_synthetic.emotions["fear"]).to eq(0)
    end

    it "ignores unknown emotions" do
      expect { bishop_synthetic.adjust_emotions(confusion: 50) }.not_to raise_error
    end
  end

  describe "fatigue" do
    it "defaults to 0" do
      expect(bishop_synthetic.fatigue).to eq(0)
    end
  end

  describe "llm_context" do
    it "can create an llm_context" do
      context = bishop_synthetic.ensure_llm_context
      expect(context).to be_a(LlmContext)
      expect(context).to be_persisted
      expect(context.synthetic).to eq(bishop_synthetic)
    end

    it "returns existing context on subsequent calls" do
      first = bishop_synthetic.ensure_llm_context
      second = bishop_synthetic.ensure_llm_context
      expect(first.id).to eq(second.id)
    end
  end
end
