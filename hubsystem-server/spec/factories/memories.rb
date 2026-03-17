FactoryBot.define do
  factory :memory do
    association :participant, factory: :human_participant
    scope { "personal" }
    sequence(:content) { |n| "Memory content #{n}" }
    metadata { {} }
    embedding { Array.new(1536, 0.1) }
  end
end
