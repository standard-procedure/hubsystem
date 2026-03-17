class AddEmbeddingToMemories < ActiveRecord::Migration[8.1]
  def change
    add_column :memories, :embedding, :vector, limit: 1536
  end
end
