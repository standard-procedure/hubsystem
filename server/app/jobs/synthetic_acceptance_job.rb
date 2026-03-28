# frozen_string_literal: true

class SyntheticAcceptanceJob < ApplicationJob
  queue_as :default

  def perform(conversation_id)
    conversation = Conversation.find(conversation_id)
    return unless conversation.requested?
    return unless conversation.recipient.is_a?(User::Synthetic)

    conversation.update!(status: :active)

    # Process the conversation subject as the opening message
    pipeline = Synthetic::Pipeline.new(conversation.recipient)
    response_text = pipeline.process(conversation.subject)

    if response_text.present?
      conversation.messages.create!(sender: conversation.recipient, content: response_text)
    end
  end
end
