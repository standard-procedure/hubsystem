class CreateConversationParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :conversation_participants do |t|
      t.belongs_to :conversation, foreign_key: true, null: false
      t.belongs_to :user, foreign_key: true, null: false
      t.integer :participant_type, default: 0, null: false
      t.timestamps
    end
  end
end
