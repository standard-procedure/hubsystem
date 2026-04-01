class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.string :subject, default: "", null: false
      t.integer :status_badge, default: 0, null: false
      t.integer :status, default: 0, null: false
      t.text :tags, array: true, default: [], null: false
      t.timestamps
    end
  end
end
