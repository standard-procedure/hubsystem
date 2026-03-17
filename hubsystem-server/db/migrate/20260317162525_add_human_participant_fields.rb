class AddHumanParticipantFields < ActiveRecord::Migration[8.1]
  def change
    add_column :participants, :token, :string
    add_index :participants, :token, unique: true
  end
end
