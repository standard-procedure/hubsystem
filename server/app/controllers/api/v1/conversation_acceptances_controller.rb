# frozen_string_literal: true

class Api::V1::ConversationAcceptancesController < Api::V1::BaseController
  def create
    conversation = Conversation.involving(current_user).find(params[:conversation_id])
    if conversation.requested? && conversation.recipient == current_user
      conversation.update!(status: :active)
      render json: {id: conversation.id, status: conversation.status}
    else
      render json: {error: "Cannot accept this conversation"}, status: :unprocessable_entity
    end
  end
end
