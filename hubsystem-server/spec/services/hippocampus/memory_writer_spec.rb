require "rails_helper"

RSpec.describe Hippocampus::MemoryWriter do
  let(:embedding_provider) { double("EmbeddingProvider") }
  let(:writer) { described_class.new(embedding_provider: embedding_provider) }
  let(:agent) { create(:agent_participant) }
  let(:embedding) { Array.new(1536, 0.2) }

  before do
    allow(embedding_provider).to receive(:embed).and_return(embedding)
  end

  describe "#write" do
    it "creates a Memory record with the given content" do
      expect {
        writer.write(participant: agent, content: "New memory content")
      }.to change(Memory, :count).by(1)
    end

    it "stores the embedding from the provider" do
      memory = writer.write(participant: agent, content: "Test content")
      expect(memory.embedding).to eq(embedding)
    end

    it "sets the scope" do
      memory = writer.write(participant: agent, content: "Test", scope: :personal)
      expect(memory.scope).to eq("personal")
    end

    it "stores metadata" do
      memory = writer.write(participant: agent, content: "Test", metadata: { source: "pipeline" })
      expect(memory.metadata).to eq({ "source" => "pipeline" })
    end

    it "deduplicates on content + participant" do
      writer.write(participant: agent, content: "Same content")
      expect {
        writer.write(participant: agent, content: "Same content")
      }.not_to change(Memory, :count)
    end

    it "creates separate records for different participants" do
      other_agent = create(:agent_participant)
      writer.write(participant: agent, content: "Same content")
      expect {
        writer.write(participant: other_agent, content: "Same content")
      }.to change(Memory, :count).by(1)
    end

    it "calls the embedding provider with the content" do
      expect(embedding_provider).to receive(:embed).with("Test content").and_return(embedding)
      writer.write(participant: agent, content: "Test content")
    end
  end
end
