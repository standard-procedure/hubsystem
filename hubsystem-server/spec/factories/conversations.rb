FactoryBot.define do
  factory :conversation do
    subject { "Test conversation" }
  end

  factory :conversation_membership do
    association :conversation
    association :participant, factory: :human_participant
  end
end
