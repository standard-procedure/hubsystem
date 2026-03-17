require "rails_helper"

RSpec.describe Hippocampus::MemoryRetriever do
  let(:retriever) { described_class.new }
  let(:agent) { create(:agent_participant, agent_class: "TestAgent") }

  describe "#retrieve" do
    it "returns personal memories for the agent" do
      memory = create(:memory, participant: agent, scope: "personal",
                      embedding: Array.new(1536, 0.1))
      results = retriever.retrieve(agent: agent, query: "test")
      ids = results.map { |r| r.is_a?(Hash) ? r[:id] : r.id }
      expect(ids).to include(memory.id)
    end

    it "returns class memories for the same agent_class" do
      other_agent = create(:agent_participant, agent_class: "TestAgent")
      memory = create(:memory, participant: other_agent, scope: "class_memory",
                      agent_class: "TestAgent", embedding: Array.new(1536, 0.1))
      results = retriever.retrieve(agent: agent, query: "test")
      ids = results.map { |r| r.is_a?(Hash) ? r[:id] : r.id }
      expect(ids).to include(memory.id)
    end

    it "does not return class memories from a different agent_class" do
      other_agent = create(:agent_participant, agent_class: "OtherAgent")
      memory = create(:memory, participant: other_agent, scope: "class_memory",
                      agent_class: "OtherAgent", embedding: Array.new(1536, 0.1))
      results = retriever.retrieve(agent: agent, query: "test")
      ids = results.map { |r| r.is_a?(Hash) ? r[:id] : r.id }
      expect(ids).not_to include(memory.id)
    end

    it "excludes knowledge_base memories when agent lacks the capability" do
      memory = create(:memory, participant: agent, scope: "knowledge_base",
                      embedding: Array.new(1536, 0.1))
      results = retriever.retrieve(agent: agent, query: "test")
      ids = results.map { |r| r.is_a?(Hash) ? r[:id] : r.id }
      expect(ids).not_to include(memory.id)
    end

    it "includes knowledge_base memories when agent has 'knowledge_base' capability" do
      group = create(:group)
      create(:security_pass, participant: agent, group: group, capabilities: ["knowledge_base"])
      memory = create(:memory, participant: agent, scope: "knowledge_base",
                      embedding: Array.new(1536, 0.1))
      results = retriever.retrieve(agent: agent, query: "test")
      ids = results.map { |r| r.is_a?(Hash) ? r[:id] : r.id }
      expect(ids).to include(memory.id)
    end

    it "filters by scope when provided" do
      personal = create(:memory, participant: agent, scope: "personal",
                        embedding: Array.new(1536, 0.1))
      class_mem = create(:memory, participant: agent, scope: "class_memory",
                         agent_class: agent.agent_class, embedding: Array.new(1536, 0.1))
      results = retriever.retrieve(agent: agent, query: "test", scope: "personal")
      ids = results.map { |r| r.is_a?(Hash) ? r[:id] : r.id }
      expect(ids).to include(personal.id)
      expect(ids).not_to include(class_mem.id)
    end

    it "respects the limit parameter" do
      5.times do |i|
        create(:memory, participant: agent, scope: "personal",
               content: "Memory #{i}", embedding: Array.new(1536, 0.1))
      end
      results = retriever.retrieve(agent: agent, query: "test", limit: 3)
      expect(results.length).to eq(3)
    end

    context "tier parameter" do
      let!(:memory) do
        create(:memory, participant: agent, scope: "personal",
               summary: "Short summary", excerpt: "Longer excerpt text",
               content: "Full content", embedding: Array.new(1536, 0.1))
      end

      it "returns id and summary hashes for tier: :l0" do
        results = retriever.retrieve(agent: agent, query: "test", tier: :l0)
        expect(results).to be_an(Array)
        expect(results.first).to include(:id, :summary)
      end

      it "returns records with summary and excerpt for tier: :l1 (default)" do
        results = retriever.retrieve(agent: agent, query: "test", tier: :l1)
        expect(results).to be_present
        first = results.first
        expect(first).to respond_to(:summary)
        expect(first).to respond_to(:excerpt)
      end

      it "returns records with full content for tier: :l2" do
        results = retriever.retrieve(agent: agent, query: "test", tier: :l2)
        expect(results).to be_present
        first = results.first
        expect(first).to respond_to(:content)
      end
    end

    context "paths filter" do
      it "filters memories by paths when provided" do
        memory_with_path = create(:memory, participant: agent, scope: "personal",
                                  paths: ["Projects/HubSystem"],
                                  embedding: Array.new(1536, 0.1))
        _other_memory = create(:memory, participant: agent, scope: "personal",
                               paths: ["Topics/Ruby"],
                               embedding: Array.new(1536, 0.1))
        results = retriever.retrieve(agent: agent, query: "test", paths: ["Projects/HubSystem"])
        ids = results.map { |r| r.is_a?(Hash) ? r[:id] : r.id }
        expect(ids).to include(memory_with_path.id)
        expect(ids.length).to eq(1)
      end
    end
  end
end
