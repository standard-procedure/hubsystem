# frozen_string_literal: true

class Api::V1::ConversationClosuresController < Api::V1::BaseController
  def create
    conversation = Conversation.involving(current_user).find(params[:conversation_id])
    if conversation.active?
      conversation.update!(status: :closed, closed_at: Time.current)
      render json: {id: conversation.id, status: conversation.status}
    else
      render json: {error: "Cannot close this conversation"}, status: :unprocessable_entity
    end
  end
end
