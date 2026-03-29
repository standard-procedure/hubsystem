# frozen_string_literal: true

require "rails_helper"

RSpec.describe Embeddable, type: :model do
  fixtures :users, :humans, :synthetics, :synthetic_classes

  let(:bishop) { users(:bishop) }
  let(:bishop_synthetic) { synthetics(:bishop_synthetic) }

  describe "after_save callback" do
    it "enqueues GenerateEmbeddingJob when content changes" do
      memory = Synthetic::Memory.create!(synthetic: bishop_synthetic, content: "Initial fact", tags: ["test"])

      expect {
        memory.update!(content: "Updated fact")
      }.to have_enqueued_job(GenerateEmbeddingJob).with("Synthetic::Memory", memory.id)
    end

    it "does not enqueue when non-content fields change" do
      memory = Synthetic::Memory.create!(synthetic: bishop_synthetic, content: "A fact", tags: ["test"])

      expect {
        memory.update!(tags: ["updated"])
      }.not_to have_enqueued_job(GenerateEmbeddingJob)
    end

    it "enqueues for Document when title or content changes" do
      doc = Document.create!(author: bishop, title: "Guide", content: "How to do things", tags: ["guide"])

      expect {
        doc.update!(title: "Updated Guide")
      }.to have_enqueued_job(GenerateEmbeddingJob).with("Document", doc.id)
    end
  end

  describe "#embeddable_text" do
    it "returns content for Synthetic::Memory" do
      memory = Synthetic::Memory.new(content: "A remembered fact")
      expect(memory.embeddable_text).to eq("A remembered fact")
    end

    it "returns title and content for Document" do
      doc = Document.new(title: "My Guide", content: "Some content")
      expect(doc.embeddable_text).to eq("My Guide\n\nSome content")
    end
  end

  describe ".embedding_model" do
    it "returns the configured embedding model" do
      expect(Synthetic::Memory.embedding_model).to eq(Rails.application.config.llm_models["embedding"])
    end
  end
end
