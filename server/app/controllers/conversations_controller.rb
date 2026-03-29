# frozen_string_literal: true

class ConversationsController < ApplicationController
  def index
    @conversations = if params[:archived]
      Conversation.involving(Current.user).closed.includes(:initiator, :recipient).order(closed_at: :desc)
    else
      Conversation.involving(Current.user).open.includes(:initiator, :recipient).order(updated_at: :desc)
    end
    render Views::Conversations::Index.new(user: Current.user, conversations: @conversations, archived: params[:archived].present?)
  end

  def show
    @conversation = Conversation.involving(Current.user).includes(messages: :sender).find(params[:id])
    @conversation.messages.where.not(sender: Current.user).unread.update_all(read_at: Time.current)
    render Views::Conversations::Show.new(user: Current.user, conversation: @conversation)
  end

  def new
    redirect_to users_path, notice: "Find a user to start a conversation with."
  end
end
