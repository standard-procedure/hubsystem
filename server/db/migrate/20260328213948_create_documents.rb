class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.references :author, null: false, foreign_key: {to_table: :users}
      t.string :title, null: false
      t.text :content, null: false
      t.text :tags, array: true, default: [], null: false
      t.vector :embedding, limit: 768

      t.timestamps
    end
  end
end
