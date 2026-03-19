# frozen_string_literal: true

class User::Identity < ApplicationRecord
  belongs_to :user, inverse_of: :identities
  validates :provider, presence: true
  validates :uid, presence: true

  def self.authenticate(omniauth) = find_by!(uid: omniauth["uid"], provider: omniauth["provider"])
end
