class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :name, null: false
      t.string :uid, null: false
      t.string :type, null: false
      t.json :data
      t.timestamps
    end
    add_index :users, :uid, unique: true
  end
end
