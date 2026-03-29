class AddStateToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :state, :string, null: false, default: "offline"
    add_index :users, :state
  end
end
