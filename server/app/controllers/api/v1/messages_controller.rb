# frozen_string_literal: true

class Api::V1::MessagesController < Api::V1::BaseController
  def index
    messages = if params[:search].present?
      current_user.messages.where("conversation_messages.contents ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:search])}%")
    else
      current_user.unread_messages
    end
    render json: messages.page(page_number).map { |m| message_json(m) }
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
end
