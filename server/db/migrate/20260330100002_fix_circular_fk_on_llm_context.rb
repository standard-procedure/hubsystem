class FixCircularFkOnLlmContext < ActiveRecord::Migration[8.1]
  def up
    # Remove the FK from messages → tool_calls and re-add with ON DELETE SET NULL
    # This breaks the circular dependency: messages can be deleted without
    # first deleting tool_calls, because the back-reference just gets nullified.
    remove_foreign_key :llm_context_messages, :llm_context_tool_calls
    add_foreign_key :llm_context_messages, :llm_context_tool_calls, on_delete: :nullify
  end

  def down
    remove_foreign_key :llm_context_messages, :llm_context_tool_calls
    add_foreign_key :llm_context_messages, :llm_context_tool_calls
  end
end
