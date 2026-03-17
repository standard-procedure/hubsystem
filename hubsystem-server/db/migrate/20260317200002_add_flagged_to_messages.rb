class AddFlaggedToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :flagged, :boolean, default: false, null: false
  end
end
