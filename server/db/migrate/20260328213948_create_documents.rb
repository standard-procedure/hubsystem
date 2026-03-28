class CreateDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :documents do |t|
      t.references :author, null: false, foreign_key: {to_table: :users}
      t.string :title, null: false
      t.text :content, null: false
      t.json :tags, null: false, default: []

      t.timestamps
    end
  end
end
