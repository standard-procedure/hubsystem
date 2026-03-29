class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :uid, null: false
      t.string :role_type, null: false
      t.bigint :role_id, null: false
      t.integer :status, default: 0, null: false
      t.boolean :system_administrator, default: false, null: false
      t.timestamps
    end
    add_index :users, [:role_type, :role_id], unique: true
    add_index :users, [:status, :uid], unique: true
  end
end
