# frozen_string_literal: true

class Synthetic::MessageProcessorJob < ApplicationJob
  self.queue_adapter = :async_job
  queue_as :default

  def perform(message_id)
    message = Message.find(message_id)
    conversation = message.conversation
    synthetic = synthetic_recipient(conversation, message.sender)
    return unless synthetic

    pipeline = Synthetic::Pipeline.new(synthetic)
    response_text = pipeline.process(message.content)

    if response_text.present?
      conversation.messages.create!(sender: synthetic, content: response_text)
    end
  end

  private

  def synthetic_recipient(conversation, sender)
    other = conversation.other_participant(sender)
    other if other.synthetic?
  end
end
