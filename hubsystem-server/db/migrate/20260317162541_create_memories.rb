class CreateMemories < ActiveRecord::Migration[8.1]
  def change
    create_table :memories do |t|
      t.references :participant, null: false, foreign_key: true
      t.string :scope, null: false
      t.string :agent_class
      t.text :content, null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end
  end
end
