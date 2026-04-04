# frozen_string_literal: true

class Conversations::MessagesController < ApplicationController
  def create
    @conversation = Conversation.involving(Current.user).active.find(params[:conversation_id])
    @conversation.send_message(sender: Current.user, contents: params[:conversation_message][:contents])
    redirect_to conversation_path(@conversation)
  end
end
