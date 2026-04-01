RubyLLM.configure do |config|
  config.use_new_acts_as = true
end

Rails.application.config.embeddings = RubyLLM::Context.new(
  RubyLLM::Configuration.new.tap do |c|
    c.openai_api_key = "ollama"
    c.openai_api_base = ENV.fetch("OLLAMA_HOST", "http://localhost:11434") + "/v1"
    c.default_embedding_model = ENV.fetch("EMBEDDING_MODEL", "nomic-embed-text")
  end
)
