FactoryBot.define do
  factory :memory do
    association :participant, factory: :human_participant
    scope { "personal" }
    content { "I remember this thing." }
    metadata { {} }
  end
end
