# frozen_string_literal: true

class Api::V1::ConversationRejectionsController < Api::V1::BaseController
  def create
    conversation = Conversation.involving(current_user).find(params[:conversation_id])
    if conversation.requested? && conversation.recipient == current_user
      conversation.update!(status: :closed, closed_at: Time.current)
      render json: {id: conversation.id, status: conversation.status}
    else
      render json: {error: "Cannot reject this conversation"}, status: :unprocessable_entity
    end
  end
end
