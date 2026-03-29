# frozen_string_literal: true

class Api::V1::ConversationRejectionsController < Api::V1::BaseController
  def create
    conversation = Conversation.involving(current_user).find(params[:conversation_id])
    conversation.reject!(by: current_user)
    render json: {id: conversation.id, status: conversation.status}
  end
end
