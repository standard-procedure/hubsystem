class LLMProvider
  STUB_RESPONSE = "stub response"
  STUB_EMBEDDING = Array.new(1536, 0.0)

  def self.models_config
    Rails.application.config_for(:models)
  end

  def self.model_for(role)
    models_config[role.to_s]
  end

  def self.stub?
    model_for(:main_turn) == "stub"
  end

  # Returns a callable that takes (system_prompt, user_message) and returns a string
  def self.for_role(role)
    if stub?
      ->(_system, _user) { STUB_RESPONSE }
    else
      model = model_for(role)
      ->(system_prompt, user_message) do
        RubyLLM.chat(model: model) do |chat|
          chat.system(system_prompt)
          chat.ask(user_message)
        end.content
      end
    end
  end

  # Returns a callable that takes text and returns a 1536-dim float array
  def self.embedding_provider
    if stub?
      ->(_text) { STUB_EMBEDDING }
    else
      model = model_for(:embedding)
      ->(text) { RubyLLM.embed(text, model: model).vectors.first }
    end
  end
end
