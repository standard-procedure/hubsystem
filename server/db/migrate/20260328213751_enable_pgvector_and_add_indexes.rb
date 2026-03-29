class EnablePgvectorAndAddIndexes < ActiveRecord::Migration[8.1]
  def change
    enable_extension "vector"
    add_index :messages, [:conversation_id, :sender_id, :read_at]
  end
end
