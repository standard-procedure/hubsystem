require "rails_helper"

RSpec.describe Hippocampus::MemoryWriter do
  let(:writer) { described_class.new }
  let(:agent) { create(:agent_participant) }

  describe "#write" do
    it "creates a Memory record with the given content" do
      expect {
        writer.write(participant: agent, content: "New memory content")
      }.to change(Memory, :count).by(1)
    end

    it "stores an embedding" do
      memory = writer.write(participant: agent, content: "Test content")
      expect(memory.embedding).to be_present
      expect(memory.embedding.length).to eq(1536)
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

    it "auto-generates summary when not provided" do
      memory = writer.write(participant: agent, content: "Some content to remember")
      expect(memory.summary).to be_present
    end

    it "auto-generates excerpt when not provided" do
      memory = writer.write(participant: agent, content: "Some content to remember")
      expect(memory.excerpt).to be_present
    end

    it "accepts explicit summary and excerpt" do
      memory = writer.write(
        participant: agent,
        content: "Full content",
        summary: "My summary",
        excerpt: "My excerpt"
      )
      expect(memory.summary).to eq("My summary")
      expect(memory.excerpt).to eq("My excerpt")
    end

    it "populates paths" do
      memory = writer.write(participant: agent, content: "Some content")
      expect(memory.paths).to be_an(Array)
      expect(memory.paths).not_to be_empty
    end

    it "always includes a date path" do
      memory = writer.write(participant: agent, content: "Some content")
      date_path = Date.today.strftime("%Y/%m/%d")
      expect(memory.paths).to include(date_path)
    end
  end
end
