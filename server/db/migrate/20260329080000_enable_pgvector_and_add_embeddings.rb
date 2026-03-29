class EnablePgvectorAndAddEmbeddings < ActiveRecord::Migration[8.1]
  def change
    enable_extension "vector"
    add_column :synthetic_memories, :embedding, :vector, limit: 768
    add_column :documents, :embedding, :vector, limit: 768
  end
end
