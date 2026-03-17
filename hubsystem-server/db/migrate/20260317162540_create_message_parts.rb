class CreateMessageParts < ActiveRecord::Migration[8.1]
  def change
    create_table :message_parts do |t|
      t.references :message, null: false, foreign_key: true
      t.string :content_type, null: false
      t.string :channel_hint
      t.text :body
      t.integer :position, default: 0

      t.timestamps
    end
  end
end
