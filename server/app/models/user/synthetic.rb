# frozen_string_literal: true

class User::Synthetic < User
  has_attribute :personality, :string, default: ""
  has_attribute :temperature, :decimal, default: 0.4
end
