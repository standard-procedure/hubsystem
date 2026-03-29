# frozen_string_literal: true

require "rails_helper"

RSpec.describe GenerateEmbeddingJob, type: :job do
  fixtures :users, :humans, :synthetics, :synthetic_classes

  let(:bishop) { users(:bishop) }
  let(:bishop_synthetic) { synthetics(:bishop_synthetic) }
  let(:fake_vector) { Array.new(768) { rand(-1.0..1.0) } }
  let(:embed_response) { instance_double("RubyLLM::EmbeddingResponse", vectors: fake_vector) }
  let(:embed_config) { Synthetic::Memory.embedding_config }

  describe "#perform" do
    it "generates and stores an embedding for a Synthetic::Memory" do
      memory = Synthetic::Memory.create!(synthetic: bishop_synthetic, content: "Alice prefers mornings", tags: ["alice"])

      allow(RubyLLM).to receive(:embed)
        .with("Alice prefers mornings", model: embed_config[:model], provider: embed_config[:provider].to_sym, assume_model_exists: true)
        .and_return(embed_response)

      described_class.perform_now("Synthetic::Memory", memory.id)

      memory.reload
      expect(memory.embedding).to be_present
      expect(memory.embedding.length).to eq(768)
    end

    it "generates and stores an embedding for a Document" do
      doc = Document.create!(author: bishop, title: "Guide", content: "How to deploy", tags: ["ops"])

      allow(RubyLLM).to receive(:embed)
        .with("Guide\n\nHow to deploy", model: embed_config[:model], provider: embed_config[:provider].to_sym, assume_model_exists: true)
        .and_return(embed_response)

      described_class.perform_now("Document", doc.id)

      doc.reload
      expect(doc.embedding).to be_present
      expect(doc.embedding.length).to eq(768)
    end
  end
end
