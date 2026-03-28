# frozen_string_literal: true

class Conversation < ApplicationRecord
  belongs_to :initiator, class_name: "User"
  belongs_to :recipient, class_name: "User"
  has_many :messages, dependent: :destroy

  enum :status, requested: 0, active: 1, closed: 2

  validates :subject, presence: true
  validate :participants_are_different

  scope :involving, ->(user) { where(initiator: user).or(where(recipient: user)) }
  scope :recently_closed, -> { closed.where(closed_at: 1.day.ago..) }

  def other_participant(user)
    (user == initiator) ? recipient : initiator
  end

  def has_unread_messages_for?(user)
    messages.where.not(sender: user).where(read_at: nil).exists?
  end

  private

  def participants_are_different
    if initiator_id.present? && initiator_id == recipient_id
      errors.add(:recipient_id, "must be different from initiator")
    end
  end
end
