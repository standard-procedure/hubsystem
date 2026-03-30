# frozen_string_literal: true

class Message < ApplicationRecord
  include Turbo::Broadcastable

  broadcasts_refreshes_to :conversation
  belongs_to :conversation
  delegate :recipients, to: :conversation
  belongs_to :sender, class_name: "User"

  after_create_commit :notify_recipient, if: -> { conversation.other_participant(sender)&.synthetic? }

  validates :content, presence: true

  scope :unread, -> { where(read_at: nil) }

  def mark_as_read!
    update!(read_at: Time.current) if read_at.nil?
  end

  def reply content:, sender:
    raise ArgumentError unless String === content
    raise ArgumentError unless User === sender
    conversation.messages.create!(sender:, content:) if content.present?
  end

  private def notify_recipient
    Synthetic::MessageProcessorJob.perform_later(self, conversation.other_participant(sender))
  end
end
