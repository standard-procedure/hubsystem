# frozen_string_literal: true

class Api::V1::Conversations::MessagesController < Api::V1::BaseController
  def index
    conversation = current_user.conversations.find(params[:conversation_id])
    messages = conversation.messages.order(:created_at)
    if params[:search].present?
      messages = messages.where("conversation_messages.contents ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:search])}%")
    end
    render json: messages.page(page_number).map { |m| message_json(m) }
  end

  def create
    conversation = current_user.conversations.active.find(params[:conversation_id])
    message = conversation.send_message(sender: current_user, contents: params.dig(:message, :contents))
    render json: message_json(message), status: :created
  end
end
