# frozen_string_literal: true

class Embedding
  include HasTypeChecks

  def initialize text:
    _check text, is: String
    @text = text
    @result = Async { Rails.application.config.embeddings.embed(@text, dimensions: 768) }
  end

  def result = @result.wait

  def vectors = result.vectors
end
