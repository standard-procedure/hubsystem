class CreateConversationMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :conversation_memberships do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :participant, null: false, foreign_key: true

      t.timestamps
    end
  end
end
