require "rails_helper"

RSpec.describe Hippocampus::ClassMemoryPromoter do
  let(:embedding_provider) { double("EmbeddingProvider") }
  let(:promoter) { described_class.new(embedding_provider: embedding_provider) }
  let(:agent) { create(:agent_participant, agent_class: "TestAgent") }
  let!(:personal_memory) do
    create(:memory, participant: agent, scope: "personal", content: "Important fact",
           embedding: Array.new(1536, 0.3))
  end

  describe "#evaluate" do
    context "when confidence >= 0.8" do
      it "creates a class_memory" do
        expect {
          promoter.evaluate(personal_memory, confidence: 0.8)
        }.to change(Memory, :count).by(1)
      end

      it "creates the class memory with scope 'class_memory'" do
        promoter.evaluate(personal_memory, confidence: 0.9)
        class_mem = Memory.find_by(scope: "class_memory", content: personal_memory.content)
        expect(class_mem).to be_present
      end

      it "tags the class memory with the agent's agent_class" do
        promoter.evaluate(personal_memory, confidence: 0.9)
        class_mem = Memory.find_by(scope: "class_memory", content: personal_memory.content)
        expect(class_mem.agent_class).to eq("TestAgent")
      end

      it "deduplicates: does not create a second class memory for the same content" do
        promoter.evaluate(personal_memory, confidence: 0.9)
        expect {
          promoter.evaluate(personal_memory, confidence: 0.9)
        }.not_to change(Memory, :count)
      end
    end

    context "when confidence < 0.8" do
      it "does not create a class memory" do
        expect {
          promoter.evaluate(personal_memory, confidence: 0.79)
        }.not_to change(Memory, :count)
      end

      it "returns nil" do
        expect(promoter.evaluate(personal_memory, confidence: 0.5)).to be_nil
      end
    end
  end
end
