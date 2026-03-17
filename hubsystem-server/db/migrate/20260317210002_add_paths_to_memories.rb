class AddPathsToMemories < ActiveRecord::Migration[8.1]
  def change
    add_column :memories, :paths, :string, array: true, default: []
    add_index :memories, :paths, using: :gin
  end
end
