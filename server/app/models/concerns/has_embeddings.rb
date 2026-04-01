# frozen_string_literal: true

module HasEmbeddings
  extend ActiveSupport::Concern

  included do
    has_neighbors :embedding
    after_save :generate_embedding, if: :embedding_content_changed?

    scope :search, ->(query, limit: 10) { nearest_neighbors(:embedding, Embedding.new(text: query).vectors, distance: "cosine").limit(limit) }
  end

  def embeddable_text
    raise NotImplementedError, "#{self.class} must implement #embeddable_text"
  end

  def embedding_content_changed?
    raise NotImplementedError, "#{self.class} must implement #embedding_content_changed?"
  end

  private def generate_embedding = GenerateEmbedding.perform_later(self)

  class GenerateEmbedding < ApplicationJob
    include HasTypeChecks

    queue_as :default

    def perform object
      _check object, is: HasEmbeddings
      object.update_columns embedding: Embedding.new(text: object.embeddable_text).vectors
    end
  end
end
