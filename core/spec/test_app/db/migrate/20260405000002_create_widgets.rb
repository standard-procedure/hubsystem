class CreateWidgets < ActiveRecord::Migration[8.1]
  def change
    create_table :widgets do |t|
      t.string :name, null: false
      t.integer :size, default: 0
      t.timestamps
    end
  end
end
