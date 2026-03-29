class AddParentAndCategoryToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_reference :documents, :parent, foreign_key: {to_table: :documents}
    add_column :documents, :category, :string, default: "document", null: false
  end
end
