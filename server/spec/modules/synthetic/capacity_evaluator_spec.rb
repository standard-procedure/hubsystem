# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synthetic::CapacityEvaluator, type: :module do
  fixtures :users

  let(:bishop) { users(:bishop) }
  let(:evaluator) { described_class.new(bishop) }
  let(:context) { bishop.ensure_llm_context }

  describe "#process" do
    it "returns low fatigue for empty context" do
      result = evaluator.process
      expect(result.fatigue).to eq(0)
      expect(result.needs_compaction).to be false
      expect(bishop.reload.fatigue).to eq(0)
    end

    context "with real token data" do
      it "calculates fatigue from actual token counts" do
        5.times do |i|
          context.llm_context_messages.create!(
            role: "user", content: "Message #{i}",
            input_tokens: 1000, output_tokens: 500,
            llm_context: context
          )
        end

        result = evaluator.process
        # Should be > 0 and < compaction threshold
        expect(result.fatigue).to be > 0
        expect(result.needs_compaction).to be false
      end

      it "flags compaction when tokens approach context window" do
        # Create enough tokens to exceed 80% of whatever context window is configured
        window = context.llm_model&.context_window || 100_000
        tokens_needed = (window * 0.85).to_i
        messages_needed = [tokens_needed / 2000, 1].max # 1000 input + 1000 output per message

        messages_needed.times do |i|
          context.llm_context_messages.create!(
            role: "user", content: "Message #{i}",
            input_tokens: 1000, output_tokens: 1000,
            llm_context: context
          )
        end

        result = evaluator.process
        expect(result.fatigue).to be >= 80
        expect(result.needs_compaction).to be true
      end
    end

    context "without token data (fallback)" do
      it "estimates from message count" do
        50.times do |i|
          context.llm_context_messages.create!(role: "user", content: "Message #{i}", llm_context: context)
        end

        result = evaluator.process
        expect(result.fatigue).to be > 0
        expect(result.needs_compaction).to be false
      end
    end
  end
end
