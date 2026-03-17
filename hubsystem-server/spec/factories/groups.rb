FactoryBot.define do
  factory :group do
    sequence(:name) { |n| "Group #{n}" }
    group_type { "team" }
    sequence(:slug) { |n| "group-#{n}" }
  end
end
