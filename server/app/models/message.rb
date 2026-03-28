# frozen_string_literal: true

class Message < ApplicationRecord
  include Turbo::Broadcastable

  belongs_to :conversation
  belongs_to :sender, class_name: "User"

  validates :content, presence: true

  after_create_commit -> { broadcast_refresh_to conversation }
  after_create_commit :notify_synthetic_recipient

  scope :unread, -> { where(read_at: nil) }

  def mark_as_read!
    update!(read_at: Time.current) if read_at.nil?
  end

  private

  def notify_synthetic_recipient
    other = conversation.other_participant(sender)
    SyntheticResponseJob.perform_later(id) if other.is_a?(User::Synthetic)
  end
end
