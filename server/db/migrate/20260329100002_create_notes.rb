class CreateNotes < ActiveRecord::Migration[8.1]
  def change
    create_table :notes do |t|
      t.references :subject, null: false, foreign_key: {to_table: :users}
      t.references :author, null: false, foreign_key: {to_table: :users}
      t.string :visibility, null: false, default: "private"
      t.text :content, null: false
      t.timestamps
    end
    add_index :notes, [:subject_id, :author_id]
    add_index :notes, [:subject_id, :visibility]
  end
end
