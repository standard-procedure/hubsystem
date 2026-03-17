class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.string :subject
      t.references :conversation, null: true, foreign_key: true
      t.references :from, null: false, foreign_key: { to_table: :participants }
      t.references :to, null: false, foreign_key: { to_table: :participants }

      t.timestamps
    end
  end
end
