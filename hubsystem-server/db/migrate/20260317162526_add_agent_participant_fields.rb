class AddAgentParticipantFields < ActiveRecord::Migration[8.1]
  def change
    add_column :participants, :agent_class, :string
    add_column :participants, :state, :string, default: "awake"
    add_column :participants, :emotion_parameters, :jsonb, default: { happy: 75, focused: 80, irritated: 10, anxious: 10, exhausted: 0 }
  end
end
