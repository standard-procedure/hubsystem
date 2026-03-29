# frozen_string_literal: true

class ConversationAcceptancesController < ApplicationController
  def create
    @conversation = Conversation.involving(Current.user).find(params[:conversation_id])
    @conversation.accept!(by: Current.user)
    redirect_to conversation_path(@conversation)
  end
end
