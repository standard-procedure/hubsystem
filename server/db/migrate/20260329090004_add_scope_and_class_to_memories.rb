class AddScopeAndClassToMemories < ActiveRecord::Migration[8.1]
  def change
    add_column :synthetic_memories, :scope, :string, null: false, default: "personal"
    add_reference :synthetic_memories, :synthetic_class, foreign_key: true
    change_column_null :synthetic_memories, :synthetic_id, true
    add_index :synthetic_memories, :scope
  end
end
