# frozen_string_literal: true

class Conversation < ApplicationRecord
  include Turbo::Broadcastable

  belongs_to :initiator, class_name: "User"
  belongs_to :recipient, class_name: "User"
  has_many :messages, dependent: :destroy

  enum :status, requested: 0, active: 1, closed: 2

  after_update_commit :broadcast_refresh
  after_create_commit :notify_synthetic_recipient

  validates :subject, presence: true
  validate :participants_are_different

  scope :involving, ->(user) { where(initiator: user).or(where(recipient: user)) }
  scope :between, ->(user_a, user_b) {
    where(initiator: user_a, recipient: user_b).or(where(initiator: user_b, recipient: user_a))
  }
  scope :open, -> { where(status: [:requested, :active]) }
  scope :recently_closed, -> { closed.where(closed_at: 1.day.ago..) }

  def other_participant(user)
    (user == initiator) ? recipient : initiator
  end

  def pending_for?(user)
    requested? && recipient == user
  end

  def has_unread_messages_for?(user)
    messages.where.not(sender: user).where(read_at: nil).exists?
  end

  def accept!(by:)
    raise ActiveRecord::RecordInvalid.new(self), "Can only accept requested conversations" unless requested?
    raise ActiveRecord::RecordInvalid.new(self), "Only the recipient can accept" unless recipient == by
    update!(status: :active)
  end

  def reject!(by:)
    raise ActiveRecord::RecordInvalid.new(self), "Can only reject requested conversations" unless requested?
    raise ActiveRecord::RecordInvalid.new(self), "Only the recipient can reject" unless recipient == by
    update!(status: :closed, closed_at: Time.current)
  end

  def close!
    raise ActiveRecord::RecordInvalid.new(self), "Can only close active conversations" unless active?
    update!(status: :closed, closed_at: Time.current)
  end

  private

  def participants_are_different
    if initiator_id.present? && initiator_id == recipient_id
      errors.add(:recipient_id, "must be different from initiator")
    end
  end

  def notify_synthetic_recipient
    User::Synthetic::ConversationAcceptanceJob.perform_later(id) if recipient.is_a?(User::Synthetic)
  end
end
