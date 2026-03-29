# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synthetic::Compactor, type: :module do
  fixtures :users, :humans, :synthetics

  let(:bishop) { users(:bishop) }
  let(:compactor) { described_class.new(bishop) }
  let(:context) { bishop.ensure_llm_context }

  let(:llm_response) do
    {
      summary: "Bishop helped Alice with deployment. Bob asked about API docs. Charlie reported a bug.",
      facts: [
        {content: "Alice deployment scheduled for Friday", tags: ["alice", "deployment"]},
        {content: "Bug #42 reported by Charlie", tags: ["bugs"]}
      ],
      emotional_context: "Bishop felt productive and engaged."
    }.to_json
  end

  before do
    stub_llm_response(llm_response)
  end

  describe "#compact!" do
    context "with enough messages to compact" do
      before do
        30.times do |i|
          context.llm_context_messages.create!(
            role: (i.even? ? "user" : "assistant"),
            content: "Message #{i}",
            llm_context: context
          )
        end
      end

      it "keeps the most recent messages intact" do
        compactor.compact!
        messages = context.llm_context_messages.order(:created_at)
        # 10 old messages compacted → 1 summary + 20 recent = 21
        expect(messages.count).to eq(21)
        all_contents = messages.pluck(:content)
        # Recent messages preserved
        expect(all_contents).to include("Message 29")
        expect(all_contents).to include("Message 11")
        # Old messages gone
        expect(all_contents).not_to include("Message 0")
        expect(all_contents).not_to include("Message 9")
      end

      it "creates a summary message" do
        compactor.compact!
        summary = context.llm_context_messages.find_by("content LIKE ?", "%[Context summary%")
        expect(summary).to be_present
        expect(summary.role).to eq("assistant")
        expect(summary.content).to include("Bishop helped Alice")
      end

      it "includes emotional context in summary" do
        compactor.compact!
        summary = context.llm_context_messages.find_by("content LIKE ?", "%[Context summary%")
        expect(summary.content).to include("productive and engaged")
      end

      it "extracts facts as memories tagged with compaction" do
        expect {
          compactor.compact!
        }.to change(Synthetic::Memory, :count).by(2)

        memory = bishop.memories.find_by(content: "Alice deployment scheduled for Friday")
        expect(memory.tags).to include("alice", "deployment", "compaction")
      end

      it "deletes old messages" do
        compactor.compact!
        contents = context.llm_context_messages.pluck(:content)
        expect(contents).not_to include("Message 0")
        expect(contents).not_to include("Message 9")
      end

      it "recalculates fatigue after compaction" do
        bishop.update!(fatigue: 85)
        compactor.compact!
        expect(bishop.reload.fatigue).to be < 85
      end
    end

    context "with too few messages to compact" do
      before do
        15.times do |i|
          context.llm_context_messages.create!(
            role: "user", content: "Message #{i}", llm_context: context
          )
        end
      end

      it "does nothing" do
        expect {
          compactor.compact!
        }.not_to change(context.llm_context_messages, :count)
      end
    end

    context "with unparseable LLM response" do
      before do
        stub_llm_response("This is not JSON at all")
        25.times do |i|
          context.llm_context_messages.create!(
            role: "user", content: "Message #{i}", llm_context: context
          )
        end
      end

      it "uses the raw response as summary" do
        compactor.compact!
        summary = context.llm_context_messages.find_by("content LIKE ?", "%[Context summary%")
        expect(summary).to be_present
        expect(summary.content).to include("This is not JSON at all")
      end
    end
  end
end
