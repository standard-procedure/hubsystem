# frozen_string_literal: true

class User < ApplicationRecord
  has_many :identities, class_name: "User::Identity", dependent: :destroy
  has_many :sessions, class_name: "User::Session", dependent: :destroy
  has_one_attached :photo
  validate :photo_is_an_image, if: -> { photo.attached? }
  normalizes :name, with: ->(s) { s.strip }
  validates :name, presence: true
  normalizes :uid, with: ->(s) { s.strip.downcase }
  before_validation :generate_uid, if: -> { uid.blank? }
  validates :uid, presence: true, uniqueness: true

  private def generate_uid
    self.uid = "#{name}-#{Time.now.to_i}".parameterize
  end

  private def photo_is_an_image
    errors.add :photo, :invalid unless photo.blob.image?
  end

  def authenticate(omniauth) = User::Identity.authenticate(omniauth).user
end
