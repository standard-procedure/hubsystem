# frozen_string_literal: true

class LlmContext < ApplicationRecord
  acts_as_chat messages: :llm_context_messages, message_class: "LlmContext::Message", model: :llm_model

  belongs_to :synthetic
end
