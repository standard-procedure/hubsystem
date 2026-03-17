FactoryBot.define do
  factory :security_pass do
    association :participant, factory: :human_participant
    association :group
    capabilities { [] }
  end
end
