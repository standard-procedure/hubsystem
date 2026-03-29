class CreateUserIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :user_identities do |t|
      t.references :human, null: false, foreign_key: {to_table: :humans}
      t.string :provider, null: false
      t.string :uid, null: false
      t.json :data
      t.timestamps
    end
    add_index :user_identities, [:provider, :uid], unique: true
  end
end
