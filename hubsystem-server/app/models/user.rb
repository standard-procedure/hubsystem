# frozen_string_literal: true

class User < ApplicationRecord
  include HasAttributes

  has_one_attached :photo
  validate :photo_is_an_image, if: -> { photo.attached? }
  normalizes :name, with: ->(s) { s.strip }
  validates :name, presence: true
  normalizes :uid, with: ->(s) { s.strip.downcase.parameterize }
  before_validation :generate_uid, if: -> { uid.blank? }
  validates :uid, presence: true, uniqueness: true
  has_many :sessions, class_name: "User::Session", dependent: :destroy
  enum :status, active: 0, deleted: -1

  scope :system_administrators, -> { active.where(system_administrator: true) }
  scope :in_order, -> { order :name }

  def to_s = name
  def to_param = "#{id}-#{uid}".parameterize

  private def generate_uid
    self.uid = "#{name}-#{Time.now.to_i}"
  end

  private def photo_is_an_image
    errors.add :photo, :invalid unless photo.blob.image?
  end

  def authenticate(omniauth) = User::Identity.authenticate(omniauth).user
end
