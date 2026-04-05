# frozen_string_literal: true

class CreateHubSystemCommandLogEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :hub_system_command_log_entries do |t|
      t.string :command_class, null: false
      t.references :actor, polymorphic: true
      t.json :params, default: {}
      t.integer :status, default: 0
      t.text :result
      t.text :error
      t.timestamps
    end
  end
end
