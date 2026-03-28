# frozen_string_literal: true

class ConversationClosuresController < ApplicationController
  def new
    @conversation = Conversation.involving(Current.user).find(params[:conversation_id])
    render Views::ConversationClosures::New.new(user: Current.user, conversation: @conversation)
  end

  def create
    @conversation = Conversation.involving(Current.user).find(params[:conversation_id])
    if @conversation.active?
      @conversation.update!(status: :closed, closed_at: Time.current)
      redirect_to conversations_path
    else
      redirect_to conversations_path, alert: "Cannot close this conversation."
    end
  end
end
