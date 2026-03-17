require "rails_helper"

RSpec.describe Hippocampus::MemoryRetriever do
  let(:embedding_provider) { double("EmbeddingProvider") }
  let(:retriever) { described_class.new(embedding_provider: embedding_provider) }
  let(:agent) { create(:agent_participant, agent_class: "TestAgent") }
  let(:embedding) { Array.new(1536, 0.1) }

  before do
    allow(embedding_provider).to receive(:embed).and_return(embedding)
  end

  describe "#retrieve" do
    it "calls the embedding provider with the query" do
      expect(embedding_provider).to receive(:embed).with("test query").and_return(embedding)
      retriever.retrieve(agent: agent, query: "test query")
    end

    it "returns personal memories for the agent" do
      memory = create(:memory, participant: agent, scope: "personal",
                      embedding: Array.new(1536, 0.1))
      results = retriever.retrieve(agent: agent, query: "test")
      expect(results).to include(memory)
    end

    it "returns class memories for the same agent_class" do
      other_agent = create(:agent_participant, agent_class: "TestAgent")
      memory = create(:memory, participant: other_agent, scope: "class_memory",
                      agent_class: "TestAgent", embedding: Array.new(1536, 0.1))
      results = retriever.retrieve(agent: agent, query: "test")
      expect(results).to include(memory)
    end

    it "does not return class memories from a different agent_class" do
      other_agent = create(:agent_participant, agent_class: "OtherAgent")
      memory = create(:memory, participant: other_agent, scope: "class_memory",
                      agent_class: "OtherAgent", embedding: Array.new(1536, 0.1))
      results = retriever.retrieve(agent: agent, query: "test")
      expect(results).not_to include(memory)
    end

    it "excludes knowledge_base memories when agent lacks the capability" do
      memory = create(:memory, participant: agent, scope: "knowledge_base",
                      embedding: Array.new(1536, 0.1))
      results = retriever.retrieve(agent: agent, query: "test")
      expect(results).not_to include(memory)
    end

    it "includes knowledge_base memories when agent has 'knowledge_base' capability" do
      group = create(:group)
      create(:security_pass, participant: agent, group: group, capabilities: ["knowledge_base"])
      memory = create(:memory, participant: agent, scope: "knowledge_base",
                      embedding: Array.new(1536, 0.1))
      results = retriever.retrieve(agent: agent, query: "test")
      expect(results).to include(memory)
    end

    it "filters by scope when provided" do
      personal = create(:memory, participant: agent, scope: "personal",
                        embedding: Array.new(1536, 0.1))
      class_mem = create(:memory, participant: agent, scope: "class_memory",
                         agent_class: agent.agent_class, embedding: Array.new(1536, 0.1))
      results = retriever.retrieve(agent: agent, query: "test", scope: "personal")
      expect(results).to include(personal)
      expect(results).not_to include(class_mem)
    end

    it "respects the limit parameter" do
      5.times do |i|
        create(:memory, participant: agent, scope: "personal",
               content: "Memory #{i}", embedding: Array.new(1536, 0.1))
      end
      results = retriever.retrieve(agent: agent, query: "test", limit: 3)
      expect(results.length).to eq(3)
    end
  end
end
