# frozen_string_literal: true

class ConversationClosuresController < ApplicationController
  def new
    @conversation = Conversation.involving(Current.user).find(params[:conversation_id])
    render Views::ConversationClosures::New.new(user: Current.user, conversation: @conversation)
  end

  def create
    @conversation = Conversation.involving(Current.user).find(params[:conversation_id])
    @conversation.close!
    redirect_to conversations_path
  end
end
