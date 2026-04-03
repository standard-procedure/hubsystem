# frozen_string_literal: true

class Api::V1::Conversations::MessagesController < Api::V1::BaseController
  def index
    conversation = current_user.conversations.find(params[:conversation_id])
    messages = conversation.messages.order(:created_at)
    if params[:search].present?
      messages = messages.where("conversation_messages.contents ILIKE ?", "%#{params[:search]}%")
    end
    render json: messages.map { |m| message_json(m) }
  end

  def create
    conversation = current_user.conversations.active.find(params[:conversation_id])
    message = conversation.send_message(sender: current_user, contents: params.dig(:message, :contents))
    render json: {id: message.id, contents: message.contents, created_at: message.created_at}, status: :created
  end

  private

  def message_json(message)
    {
      id: message.id,
      sender: {id: message.sender.id, name: message.sender.name},
      contents: message.contents,
      read: message.read_by?(current_user).present?,
      created_at: message.created_at
    }
  end
end
