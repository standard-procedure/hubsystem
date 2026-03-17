class AddSuspicionCountToParticipants < ActiveRecord::Migration[8.1]
  def change
    add_column :participants, :suspicion_count, :integer, default: 0, null: false
  end
end
