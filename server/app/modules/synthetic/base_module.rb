# frozen_string_literal: true

class Synthetic
  class BaseModule
    def initialize(synthetic)
      @synthetic = synthetic
    end

    private

    def evaluate(system_prompt, content)
      chat = RubyLLM.chat
        .with_model(llm_model(:low))
        .with_instructions(system_prompt)
      chat.ask(content).content
    end

    def llm_model(tier)
      Rails.application.config.llm_models[tier.to_s]
    end
  end
end
