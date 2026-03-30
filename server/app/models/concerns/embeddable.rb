# frozen_string_literal: true

module Embeddable
  extend ActiveSupport::Concern

  included do
    has_neighbors :embedding
    after_save :enqueue_embedding, if: :embedding_content_changed?
  end

  class_methods do
    def semantic_search(query, limit: 10)
      config = embedding_config
      embedding = Rails.application.config.ollama_context.embed(query, model: config[:model], provider: config[:provider].to_sym, assume_model_exists: true).vectors
      nearest_neighbors(:embedding, embedding, distance: "cosine").limit(limit)
    end

    def embedding_config
      Rails.application.config.llm_models[:embedding]
    end

    def embedding_model
      embedding_config[:model]
    end
  end

  def embeddable_text
    raise NotImplementedError, "#{self.class} must implement #embeddable_text"
  end

  def embedding_content_changed?
    raise NotImplementedError, "#{self.class} must implement #embedding_content_changed?"
  end

  private

  def enqueue_embedding
    GenerateEmbeddingJob.perform_later(self.class.name, id)
  end
end
