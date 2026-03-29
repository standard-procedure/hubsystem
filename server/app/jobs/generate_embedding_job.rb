# frozen_string_literal: true

class GenerateEmbeddingJob < ApplicationJob
  queue_as :default

  def perform(class_name, id)
    record = class_name.constantize.find(id)
    response = RubyLLM.embed(record.embeddable_text, model: record.class.embedding_model, provider: :openai, assume_model_exists: true)
    record.update_column(:embedding, response.vectors)
  end
end
