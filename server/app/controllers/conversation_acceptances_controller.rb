# frozen_string_literal: true

class ConversationAcceptancesController < ApplicationController
  def create
    @conversation = Conversation.involving(Current.user).find(params[:conversation_id])
    if @conversation.requested? && @conversation.recipient == Current.user
      @conversation.update!(status: :active)
      redirect_to conversation_path(@conversation)
    else
      redirect_to conversations_path, alert: "Cannot accept this conversation."
    end
  end
end
