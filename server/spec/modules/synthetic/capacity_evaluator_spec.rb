# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synthetic::CapacityEvaluator, type: :module do
  fixtures :users

  let(:bishop) { users(:bishop) }
  let(:evaluator) { described_class.new(bishop) }

  before { bishop.ensure_llm_context }

  describe "#process" do
    it "returns low fatigue for empty context" do
      result = evaluator.process
      expect(result.fatigue).to eq(0)
      expect(result.needs_compaction).to be false
      expect(bishop.reload.fatigue).to eq(0)
    end

    it "calculates fatigue based on message count" do
      context = bishop.llm_context
      50.times do |i|
        context.llm_context_messages.create!(role: "user", content: "Message #{i}", llm_context: context)
      end

      result = evaluator.process
      expect(result.fatigue).to eq(25) # 50 * 500 / 100_000 * 100 = 25%
      expect(result.needs_compaction).to be false
    end

    it "flags compaction needed at high fatigue" do
      context = bishop.llm_context
      170.times do |i|
        context.llm_context_messages.create!(role: "user", content: "Message #{i}", llm_context: context)
      end

      result = evaluator.process
      expect(result.fatigue).to eq(85)
      expect(result.needs_compaction).to be true
    end
  end
end
