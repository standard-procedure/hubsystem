class LlmContext::Message < ApplicationRecord
  acts_as_message chat: :llm_context, tool_calls: :llm_context_tool_calls, tool_call_class: "LlmContext::ToolCall", tool_calls_foreign_key: :llm_context_message_id, model: :llm_model
end
