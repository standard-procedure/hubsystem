# frozen_string_literal: true

class User < ApplicationRecord
  delegated_type :role, types: %w[Human Synthetic], dependent: :destroy

  # Delegate Synthetic-specific methods so the pipeline can work with User records directly
  delegate :ensure_llm_context, :memories, :adjust_emotions, :personality, :temperature,
    :fatigue, :fatigue=, :emotions, :emotions=, :llm_tier, :operating_system,
    :synthetic_class, to: :role, allow_nil: true

  # Delegate Human-specific methods
  delegate :identities, to: :role, allow_nil: true

  has_one_attached :photo
  validate :photo_is_an_image, if: -> { photo.attached? }
  normalizes :name, with: ->(s) { s.strip }
  validates :name, presence: true
  normalizes :uid, with: ->(s) { s.strip.downcase.parameterize }
  before_validation :generate_uid, if: -> { uid.blank? }
  validates :uid, presence: true, uniqueness: true
  has_many :sessions, class_name: "User::Session", dependent: :destroy
  has_many :authored_documents, class_name: "Document", foreign_key: :author_id, dependent: :destroy, inverse_of: :author
  has_many :initiated_conversations, class_name: "Conversation", foreign_key: :initiator_id, dependent: :destroy, inverse_of: :initiator
  has_many :received_conversations, class_name: "Conversation", foreign_key: :recipient_id, dependent: :destroy, inverse_of: :recipient
  has_many :notes_about, class_name: "Note", foreign_key: :subject_id, dependent: :destroy
  has_many :authored_notes, class_name: "Note", foreign_key: :author_id, dependent: :destroy
  enum :status, active: 0, deleted: -1

  HUMAN_STATES = %w[offline online do_not_disturb].freeze
  SYNTHETIC_STATES = %w[offline online busy tired].freeze

  def go_online! = update!(state: "online")
  def go_offline! = update!(state: "offline")

  def state_color
    case state
    when "online" then :nominal
    when "busy", "tired", "do_not_disturb" then :warning
    when "offline" then :offline
    else :offline
    end
  end

  scope :system_administrators, -> { active.where(system_administrator: true) }
  scope :in_order, -> { order :name }
  scope :search_by_name_or_uid, ->(term) {
    sanitized = sanitize_sql_like(term)
    active.where("name LIKE ? OR uid LIKE ?", "%#{sanitized}%", "%#{sanitized}%")
  }

  def to_s = name
  def to_param = "#{id}-#{uid}".parameterize

  private def generate_uid
    self.uid = "#{name}-#{Time.now.to_i}"
  end

  private def photo_is_an_image
    errors.add :photo, :invalid unless photo.blob.image?
  end
end
