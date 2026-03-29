# frozen_string_literal: true

Rails.application.config.llm_models = Rails.application.config_for(:llm_models)

# Ensure all configured models exist in the LlmModel registry (database).
# Ollama models (qwen2.5, nomic-embed-text) aren't in RubyLLM's built-in
# registry, so we create placeholder records for acts_as_chat to find them.
Rails.application.config.after_initialize do
  next unless ActiveRecord::Base.connection.table_exists?(:llm_models)

  Rails.application.config.llm_models.each_value do |tier_config|
    model_id = tier_config[:model]
    provider = tier_config[:provider]
    next if model_id.blank? || provider.blank?

    LlmModel.find_or_create_by(provider: provider, model_id: model_id) do |m|
      m.name = model_id
    end
  end
rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid,
  ActiveRecord::ConnectionNotEstablished, ActiveRecord::RecordInvalid
  # Skip during db:create, missing tables, or if records already exist
end
