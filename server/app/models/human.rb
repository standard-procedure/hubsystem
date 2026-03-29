# frozen_string_literal: true

class Human < ApplicationRecord
  self.table_name = "humans"
  has_one :user, as: :role, dependent: :destroy, touch: true
  has_many :identities, class_name: "User::Identity", foreign_key: :human_id, dependent: :destroy, inverse_of: :human
end
