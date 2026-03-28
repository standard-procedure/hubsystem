class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.string :subject, null: false
      t.integer :status, null: false, default: 0
      t.references :initiator, null: false, foreign_key: {to_table: :users}
      t.references :recipient, null: false, foreign_key: {to_table: :users}
      t.datetime :closed_at

      t.timestamps
    end

    add_index :conversations, [:initiator_id, :status]
    add_index :conversations, [:recipient_id, :status]
  end
end
