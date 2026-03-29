# frozen_string_literal: true

class Api::V1::ConversationAcceptancesController < Api::V1::BaseController
  def create
    conversation = Conversation.involving(current_user).find(params[:conversation_id])
    conversation.accept!(by: current_user)
    render json: {id: conversation.id, status: conversation.status}
  end
end
