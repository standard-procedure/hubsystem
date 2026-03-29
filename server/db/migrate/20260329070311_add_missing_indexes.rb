class AddMissingIndexes < ActiveRecord::Migration[8.1]
  def change
    add_index :user_identities, [:provider, :uid], unique: true
    add_index :messages, [:conversation_id, :sender_id, :read_at]
  end
end
