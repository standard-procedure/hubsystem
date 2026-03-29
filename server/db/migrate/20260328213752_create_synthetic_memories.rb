class CreateSyntheticMemories < ActiveRecord::Migration[8.1]
  def change
    create_table :synthetic_memories do |t|
      t.references :synthetic, null: false, foreign_key: {to_table: :synthetics}
      t.text :content, null: false
      t.text :tags, array: true, default: [], null: false
      t.vector :embedding, limit: 768

      t.timestamps
    end
  end
end
