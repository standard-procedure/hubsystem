# frozen_string_literal: true

class ConversationRejectionsController < ApplicationController
  def create
    @conversation = Conversation.involving(Current.user).find(params[:conversation_id])
    if @conversation.requested? && @conversation.recipient == Current.user
      @conversation.update!(status: :closed, closed_at: Time.current)
      redirect_to conversations_path
    else
      redirect_to conversations_path, alert: "Cannot reject this conversation."
    end
  end
end
