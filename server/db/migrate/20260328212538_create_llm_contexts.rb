class CreateLlmContexts < ActiveRecord::Migration[8.1]
  def change
    create_table :llm_contexts do |t|
      t.references :synthetic, null: false, foreign_key: {to_table: :synthetics}
      t.timestamps
    end
  end
end
