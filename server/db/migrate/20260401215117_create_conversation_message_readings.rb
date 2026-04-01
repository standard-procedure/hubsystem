class CreateConversationMessageReadings < ActiveRecord::Migration[8.1]
  def change
    create_table :conversation_message_readings do |t|
      t.belongs_to :message, foreign_key: {to_table: "conversation_messages"}
      t.belongs_to :user, foreign_key: true
      t.timestamps
    end
  end
end
