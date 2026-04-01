# frozen_string_literal: true

class User < ApplicationRecord
  include HasStatusBadge
  include HasAttachments
  include HasTags
  include User::Conversations

  normalizes :name, with: ->(s) { s.to_s.strip }
  validates :name, presence: true
  normalizes :uid, with: ->(s) { s.to_s.strip.downcase.parameterize }
  before_validation :generate_uid, if: -> { uid.blank? }
  validates :uid, presence: true, uniqueness: true

  has_many :identities, class_name: "User::Identity", dependent: :destroy
  has_many :sessions, class_name: "User::Session", dependent: :destroy

  has_attachment :photo
  validate_image_for :photo

  enum :status, active: 0, deleted: -1
  normalizes :status_message, with: ->(s) { s.to_s.strip }

  scope :system_administrators, -> { active.where(system_administrator: true) }
  scope :in_order, -> { order :name }
  scope :search_by_name_or_uid, ->(term) { active.where("name LIKE :term OR uid LIKE :term", term: sanitize_sql_like(term)) }

  def to_s = name
  def to_param = "#{id}-#{uid}".parameterize

  private def generate_uid
    self.uid = "#{name}-#{Time.now.to_i}"
  end
end
