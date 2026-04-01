class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :uid, null: false
      t.text :description
      t.integer :status, default: 0, null: false
      t.integer :status_badge, default: 0, null: false
      t.string :status_message, default: ""
      t.boolean :system_administrator, default: false, null: false
      t.timestamps
    end
    add_index :users, [:status, :uid], unique: true
  end
end
