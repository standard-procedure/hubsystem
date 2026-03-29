class ConvertTagsToTextArrays < ActiveRecord::Migration[8.1]
  def up
    # Create a helper function to convert json arrays to text arrays
    # (ALTER COLUMN ... USING doesn't allow subqueries, but allows function calls)
    execute <<~SQL
      CREATE OR REPLACE FUNCTION json_to_text_array(val json) RETURNS text[] AS $$
        SELECT coalesce(array_agg(elem), '{}') FROM json_array_elements_text(val) AS elem;
      $$ LANGUAGE sql IMMUTABLE;
    SQL

    %i[synthetic_memories documents tasks].each do |table|
      execute "ALTER TABLE #{table} ALTER COLUMN tags DROP DEFAULT;"
      execute "ALTER TABLE #{table} ALTER COLUMN tags TYPE text[] USING json_to_text_array(tags);"
      execute "ALTER TABLE #{table} ALTER COLUMN tags SET DEFAULT '{}';"
    end

    execute "DROP FUNCTION json_to_text_array(json);"
  end

  def down
    %i[synthetic_memories documents tasks].each do |table|
      change_column table, :tags, :json, default: "[]", using: "to_json(tags)"
    end
  end
end
