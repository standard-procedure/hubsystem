class AgentParticipant < Participant
  STATES = %w[awake napping].freeze

  validates :agent_class, presence: true
  validates :state, inclusion: { in: STATES }
end
