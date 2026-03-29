# frozen_string_literal: true

class Api::V1::Conversations::MessagesController < Api::V1::BaseController
  def index
    conversation = Conversation.involving(current_user).find(params[:conversation_id])
    messages = conversation.messages.includes(:sender).order(:created_at)
    render json: messages.map { |m|
      {id: m.id, sender: {id: m.sender.id, name: m.sender.name}, content: m.content, read_at: m.read_at, created_at: m.created_at}
    }
  end

  def create
    conversation = Conversation.involving(current_user).active.find(params[:conversation_id])
    message = conversation.messages.create!(sender: current_user, content: params[:message][:content])
    render json: {id: message.id, content: message.content, created_at: message.created_at}, status: :created
  end
end
