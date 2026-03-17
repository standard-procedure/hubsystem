class AddTieredContentToMemories < ActiveRecord::Migration[8.1]
  def change
    add_column :memories, :summary, :string
    add_column :memories, :excerpt, :text
  end
end
