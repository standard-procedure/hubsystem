class LlmContext::ToolCall < ApplicationRecord
  acts_as_tool_call message: :llm_context_message, message_class: "LlmContext::Message"
end
