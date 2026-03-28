# frozen_string_literal: true

class Conversations::MessagesController < ApplicationController
  def create
    @conversation = Conversation.involving(Current.user).active.find(params[:conversation_id])
    @conversation.messages.create!(sender: Current.user, content: params[:message][:content])
    redirect_to conversation_path(@conversation)
  end
end
