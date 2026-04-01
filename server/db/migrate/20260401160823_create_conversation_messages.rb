class CreateConversationMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :conversation_messages do |t|
      t.belongs_to :conversation, foreign_key: true, null: false
      t.belongs_to :sender, foreign_key: {to_table: "users"}, null: false
      t.integer :status_badge, default: 0, null: false
      t.text :contents
      t.text :tags, array: true, default: [], null: false
      t.vector :embedding, limit: 768
      t.timestamps
    end
  end
end
