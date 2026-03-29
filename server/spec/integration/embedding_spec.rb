# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Embedding generation via Ollama", :llm, type: :model do
  fixtures :users, :humans, :synthetics

  let(:bishop) { users(:bishop) }
  let(:bishop_synthetic) { synthetics(:bishop_synthetic) }

  it "generates a 768-dimension embedding for a memory" do
    memory = Synthetic::Memory.create!(synthetic: bishop_synthetic, content: "Alice always arrives early on Mondays", tags: ["alice"])

    GenerateEmbeddingJob.perform_now("Synthetic::Memory", memory.id)

    memory.reload
    expect(memory.embedding).to be_present
    expect(memory.embedding.length).to eq(768)
  end

  it "generates a 768-dimension embedding for a document" do
    doc = Document.create!(author: bishop, title: "Onboarding Guide", content: "Welcome to the team", tags: ["onboarding"])

    GenerateEmbeddingJob.perform_now("Document", doc.id)

    doc.reload
    expect(doc.embedding).to be_present
    expect(doc.embedding.length).to eq(768)
  end

  it "finds semantically similar memories via nearest_neighbors" do
    memory = Synthetic::Memory.create!(synthetic: bishop_synthetic, content: "Alice prefers morning meetings", tags: ["alice"])
    GenerateEmbeddingJob.perform_now("Synthetic::Memory", memory.id)

    results = Synthetic::Memory.semantic_search("What time does Alice like to meet?", limit: 5)
    expect(results).to include(memory)
  end
end
