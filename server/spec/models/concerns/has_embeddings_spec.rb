# frozen_string_literal: true

require "rails_helper"

RSpec.describe HasEmbeddings do
  # Use an anonymous class backed by the conversation_messages table, which has
  # the embedding column. This avoids polluting any real model while still
  # exercising the concern against a real database table.
  let(:model_class) do
    Class.new(ApplicationRecord) do
      self.table_name = "conversation_messages"
      include HasEmbeddings
    end
  end

  describe "#embeddable_text" do
    it "raises NotImplementedError when not overridden" do
      expect { model_class.new.embeddable_text }.to raise_error(NotImplementedError)
    end

    it "can be overridden by the including class" do
      model_class.define_method(:embeddable_text) { "some text" }
      expect { model_class.new.embeddable_text }.not_to raise_error
    end
  end

  describe "#embedding_content_changed?" do
    it "raises NotImplementedError when not overridden" do
      expect { model_class.new.embedding_content_changed? }.to raise_error(NotImplementedError)
    end
  end

  describe ".search" do
    it "delegates to nearest_neighbors with the query's vectors" do
      vectors = [0.1] * 768
      embedding = instance_double(Embedding, vectors: vectors)
      allow(Embedding).to receive(:new).with(text: "hello").and_return(embedding)

      expect(model_class).to receive(:nearest_neighbors).with(:embedding, vectors, distance: "cosine").and_call_original
      model_class.search("hello")
    end

    it "applies a default limit of 10" do
      vectors = [0.1] * 768
      embedding = instance_double(Embedding, vectors: vectors)
      allow(Embedding).to receive(:new).with(text: "anything").and_return(embedding)

      relation = model_class.search("anything")
      expect(relation.limit_value).to eq(10)
    end
  end

  describe "GenerateEmbedding job" do
    it "raises ArgumentError when given an object that does not include HasEmbeddings" do
      expect {
        HasEmbeddings::GenerateEmbedding.new.perform("not an embeddable")
      }.to raise_error(ArgumentError)
    end
  end
end
