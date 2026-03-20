# frozen_string_literal: true

class User::Human < User
  has_many :identities, class_name: "User::Identity", foreign_key: :user_id, dependent: :destroy, inverse_of: :user
end
