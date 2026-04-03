# frozen_string_literal: true

class Api::V1::MessagesController < Api::V1::BaseController
  def index
    messages = if params[:search].present?
      current_user.messages.where("conversation_messages.contents ILIKE ?", "%#{params[:search]}%")
    else
      current_user.unread_messages
    end
    render json: messages.map { |m| message_json(m) }
  end

  def show
    message = current_user.messages.find(params[:id])
    conversation = message.conversation
    render json: {
      message: message_json(message),
      conversation: {
        id: conversation.id,
        subject: conversation.subject,
        messages: conversation.messages.order(:created_at).map { |m| message_json(m) }
      }
    }
  end

  private

  def message_json(message)
    {
      id: message.id,
      conversation_id: message.conversation_id,
      sender: {id: message.sender.id, name: message.sender.name},
      contents: message.contents,
      read: message.read_by?(current_user).present?,
      created_at: message.created_at
    }
  end
end
