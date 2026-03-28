class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :parent, foreign_key: {to_table: :tasks}
      t.references :creator, null: false, foreign_key: {to_table: :users}
      t.references :assignee, foreign_key: {to_table: :users}
      t.string :subject, null: false
      t.text :description
      t.integer :status, null: false, default: 0
      t.datetime :completed_at
      t.datetime :due_at
      t.string :schedule
      t.json :tags, null: false, default: []

      t.timestamps
    end

    add_index :tasks, [:assignee_id, :status]
    add_index :tasks, [:creator_id, :status]
    add_index :tasks, :due_at
  end
end
