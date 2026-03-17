FactoryBot.define do
  factory :participant, class: "HumanParticipant" do
    sequence(:name) { |n| "Participant #{n}" }
    sequence(:slug) { |n| "participant-#{n}" }
    type { "HumanParticipant" }
  end

  factory :human_participant, class: "HumanParticipant" do
    sequence(:name) { |n| "Human #{n}" }
    sequence(:slug) { |n| "human-#{n}" }
    type { "HumanParticipant" }
  end

  factory :agent_participant, class: "AgentParticipant" do
    sequence(:name) { |n| "Agent #{n}" }
    sequence(:slug) { |n| "agent-#{n}" }
    type { "AgentParticipant" }
    agent_class { "BasicAgent" }
    state { "awake" }
  end

  factory :monitor_participant, class: "MonitorParticipant" do
    sequence(:name) { |n| "Monitor #{n}" }
    sequence(:slug) { |n| "monitor-#{n}" }
    type { "MonitorParticipant" }
  end
end
