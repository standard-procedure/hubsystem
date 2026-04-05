# frozen_string_literal: true

class CreateHubSystemSecurityPasses < ActiveRecord::Migration[8.1]
  def change
    create_table :hub_system_security_passes do |t|
      t.references :resource, polymorphic: true, null: false
      t.references :user, polymorphic: true, null: false
      t.string :type
      t.integer :status, default: 0
      t.json :data, default: {}
      t.timestamps
    end
  end
end
