class CreateSyntheticMemories < ActiveRecord::Migration[8.1]
  def change
    create_table :synthetic_memories do |t|
      t.references :synthetic, null: false, foreign_key: {to_table: :users}
      t.text :content, null: false
      t.json :tags, null: false, default: []

      t.timestamps
    end
  end
end
