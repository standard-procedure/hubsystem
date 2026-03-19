# frozen_string_literal: true

class User::Human < User
  has_many :identities, class_name: "User::Identity", dependent: :destroy
end
