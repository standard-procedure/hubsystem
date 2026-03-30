class AddToolCallIdToLlmContextMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :llm_context_messages, :tool_call_id, :string
    add_index :llm_context_messages, :tool_call_id
  end
end
