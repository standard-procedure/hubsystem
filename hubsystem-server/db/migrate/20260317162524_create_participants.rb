class CreateParticipants < ActiveRecord::Migration[8.1]
  def change
    create_table :participants do |t|
      t.string :name, null: false
      t.string :type, null: false
      t.string :slug, null: false
      t.text :description

      t.timestamps
    end
    add_index :participants, :slug, unique: true
  end
end
