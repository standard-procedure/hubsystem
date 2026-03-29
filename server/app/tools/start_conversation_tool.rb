# frozen_string_literal: true

class StartConversationTool < RubyLLM::Tool
  description "Start a new conversation with another user by sending them a request."

  param :recipient_name, type: "string", desc: "Name or UID of the user to start a conversation with", required: true
  param :subject, type: "string", desc: "Subject of the conversation", required: true

  def initialize(synthetic)
    @synthetic = synthetic
    super()
  end

  def execute(recipient_name:, subject:)
    recipient = User.search_by_name_or_uid(recipient_name).first
    return "User '#{recipient_name}' not found." unless recipient
    return "You cannot start a conversation with yourself." if recipient == @synthetic

    conversation = Conversation.create!(
      initiator: @synthetic,
      recipient: recipient,
      subject: subject,
      status: :requested
    )
    "Conversation request sent to #{recipient.name}: [#{conversation.id}] #{subject}"
  end
end
