# frozen_string_literal: true

class Message < ApplicationRecord
  include Turbo::Broadcastable

  belongs_to :conversation
  belongs_to :sender, class_name: "User"

  validates :content, presence: true

  broadcasts_refreshes_to :conversation
  after_create_commit :notify_synthetic_recipient

  scope :unread, -> { where(read_at: nil) }

  def mark_as_read!
    update!(read_at: Time.current) if read_at.nil?
  end

  private

  def notify_synthetic_recipient
    other = conversation.other_participant(sender)
    Synthetic::MessageProcessorJob.perform_later(id) if other.synthetic?
  end
end
