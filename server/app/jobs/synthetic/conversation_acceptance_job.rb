# frozen_string_literal: true

class Synthetic::ConversationAcceptanceJob < ApplicationJob
  queue_as :default

  def perform(conversation, recipient)
    raise ArgumentError unless Conversation === conversation
    raise ArgumentError unless User === recipient

    return unless conversation.requested?
    return unless recipient&.synthetic?

    conversation.messages.create!(sender: conversation.initiator, content: conversation.subject)
    conversation.update!(status: :active)
  end
end
