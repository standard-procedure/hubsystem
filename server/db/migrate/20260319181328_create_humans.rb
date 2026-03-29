class CreateHumans < ActiveRecord::Migration[8.1]
  def change
    create_table :humans do |t|
      t.timestamps
    end
  end
end
