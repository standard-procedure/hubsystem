# frozen_string_literal: true

class ConversationClosuresController < ApplicationController
  def create
    @conversation = Conversation.involving(Current.user).active.find(params[:conversation_id])
    @conversation.archived!
    redirect_to conversations_path
  end
end
