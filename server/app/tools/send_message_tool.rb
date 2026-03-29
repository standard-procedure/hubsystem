# frozen_string_literal: true

class SendMessageTool < SyntheticTool
  description "Send a message in an active conversation."

  param :conversation_id, type: "integer", desc: "ID of the conversation to send a message in", required: true
  param :content, type: "string", desc: "Message content", required: true

  def execute(conversation_id:, content:)
    conversation = Conversation.involving(@synthetic).find_by(id: conversation_id)
    return "Conversation #{conversation_id} not found." unless conversation
    return "Conversation is not active." unless conversation.active?

    conversation.messages.create!(sender: @synthetic, content: content)
    "Message sent in conversation [#{conversation.id}] #{conversation.subject}"
  end
end
