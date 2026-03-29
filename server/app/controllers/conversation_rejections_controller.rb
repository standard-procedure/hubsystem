# frozen_string_literal: true

class ConversationRejectionsController < ApplicationController
  def create
    @conversation = Conversation.involving(Current.user).find(params[:conversation_id])
    @conversation.reject!(by: Current.user)
    redirect_to conversations_path
  end
end
