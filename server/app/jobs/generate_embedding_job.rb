# frozen_string_literal: true

class GenerateEmbeddingJob < ApplicationJob
  queue_as :default

  def perform(class_name, id)
    record = class_name.constantize.find(id)
    config = record.class.embedding_config
    response = Rails.application.config.ollama_context.embed(record.embeddable_text, model: config[:model], provider: config[:provider].to_sym, assume_model_exists: true)
    record.update_column(:embedding, response.vectors)
  end
end
