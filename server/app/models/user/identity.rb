# frozen_string_literal: true

class User::Identity < ApplicationRecord
  belongs_to :human, inverse_of: :identities
  has_one :user, through: :human, source: :user

  validates :provider, presence: true
  validates :uid, presence: true

  def self.find_from_omniauth(auth)
    find_by(uid: auth["uid"], provider: auth["provider"])
  end
end
