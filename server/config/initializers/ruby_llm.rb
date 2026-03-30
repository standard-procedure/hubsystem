RubyLLM.configure do |config|
  openai_key = ENV.fetch("OPENAI_API_KEY", Rails.application.credentials.dig(:openai_api_key) || "not-configured")
  config.openai_api_key = openai_key

  # Route through Ollama only when no real OpenAI key is configured.
  # Set OPENAI_API_KEY to use real OpenAI; leave unset (or "not-configured") to use Ollama.
  if openai_key.blank? || openai_key == "not-configured"
    config.openai_api_base = ENV.fetch("OLLAMA_HOST", "http://localhost:11434") + "/v1"
  end

  config.anthropic_api_key = ENV.fetch("ANTHROPIC_API_KEY", Rails.application.credentials.dig(:anthropic_api_key) || "not-configured")

  config.use_new_acts_as = true
  config.model_registry_class = "LlmModel"
end
