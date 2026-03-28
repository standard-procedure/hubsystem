class AddReferencesToLlmContextsLlmContextToolCallsAndLlmContextMessages < ActiveRecord::Migration[8.1]
  def change
    add_reference :llm_contexts, :llm_model, foreign_key: true
    add_reference :llm_context_tool_calls, :llm_context_message, null: false, foreign_key: true
    add_reference :llm_context_messages, :llm_context, null: false, foreign_key: true
    add_reference :llm_context_messages, :llm_model, foreign_key: true
    add_reference :llm_context_messages, :llm_context_tool_call, foreign_key: true
  end
end
