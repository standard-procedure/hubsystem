# frozen_string_literal: true

class Synthetic
  class BaseModule
    def initialize(synthetic)
      @synthetic = synthetic
    end

    private

    def evaluate(system_prompt, content)
      config = llm_config(:low)
      chat = RubyLLM.chat(model: config[:model], provider: config[:provider].to_sym, assume_model_exists: true)
        .with_instructions(system_prompt)
      chat.ask(content).content
    end

    def llm_config(tier)
      Rails.application.config.llm_models[tier]
    end
  end
end
