FactoryBot.define do
  factory :message_part do
    association :message
    content_type { "text/plain" }
    body { "Hello, world!" }
    position { 0 }
  end
end
