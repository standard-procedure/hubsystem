FactoryBot.define do
  factory :message do
    association :from, factory: :human_participant
    association :to, factory: :human_participant
    subject { "Test message" }

    after(:create) do |message|
      create(:message_part, message: message)
    end
  end
end
