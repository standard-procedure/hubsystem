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
  has_many :initiated_conversations, class_name: "Conversation", foreign_key: :initiator_id, dependent: :destroy, inverse_of: :initiator
  has_many :received_conversations, class_name: "Conversation", foreign_key: :recipient_id, dependent: :destroy, inverse_of: :recipient
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
end
