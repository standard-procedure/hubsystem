# frozen_string_literal: true

class UserConversationsController < ApplicationController
  before_action :set_recipient

  def new
    render Views::UserConversations::New.new(recipient: @recipient)
  end

  def create
    conversation = Conversation.new(
      subject: params[:conversation][:subject],
      initiator: Current.user,
      recipient: @recipient,
      status: :requested
    )
    if conversation.save
      redirect_to conversation_path(conversation)
    else
      render Views::UserConversations::New.new(recipient: @recipient, conversation: conversation)
    end
  end

  private

  def set_recipient
    @recipient = User.find(params[:user_id])
  end
end
