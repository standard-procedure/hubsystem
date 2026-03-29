class ConvertTagsToTextArrays < ActiveRecord::Migration[8.1]
  def change
    change_column :synthetic_memories, :tags, :text, array: true, default: [], using: "ARRAY(SELECT jsonb_array_elements_text(tags::jsonb))::text[]"
    change_column :documents, :tags, :text, array: true, default: [], using: "ARRAY(SELECT jsonb_array_elements_text(tags::jsonb))::text[]"
    change_column :tasks, :tags, :text, array: true, default: [], using: "ARRAY(SELECT jsonb_array_elements_text(tags::jsonb))::text[]"
  end
end
