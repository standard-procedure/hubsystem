class CreateSecurityPasses < ActiveRecord::Migration[8.1]
  def change
    create_table :security_passes do |t|
      t.references :participant, null: false, foreign_key: true
      t.references :group, null: false, foreign_key: true
      t.jsonb :capabilities, default: []

      t.timestamps
    end
  end
end
