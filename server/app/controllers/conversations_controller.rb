# frozen_string_literal: true

class ConversationsController < ApplicationController
  def index
    @conversations = if params[:archived]
      Conversation.involving(Current.user).closed.order(closed_at: :desc)
    else
      Conversation.involving(Current.user).where(status: [:requested, :active]).order(updated_at: :desc)
    end
    render Views::Conversations::Index.new(user: Current.user, conversations: @conversations, archived: params[:archived].present?)
  end

  def show
    @conversation = Conversation.involving(Current.user).find(params[:id])
    @conversation.messages.where.not(sender: Current.user).unread.update_all(read_at: Time.current)
    render Views::Conversations::Show.new(user: Current.user, conversation: @conversation)
  end

  def new
    render Views::Conversations::New.new(user: Current.user, users: User.where.not(id: Current.user.id).in_order)
  end

  def create
    @conversation = Conversation.new(
      subject: params[:conversation][:subject],
      initiator: Current.user,
      recipient: User.find(params[:conversation][:recipient_id]),
      status: :requested
    )
    if @conversation.save
      redirect_to conversation_path(@conversation)
    else
      render Views::Conversations::New.new(user: Current.user, users: User.where.not(id: Current.user.id).in_order), status: :unprocessable_entity
    end
  end
end
