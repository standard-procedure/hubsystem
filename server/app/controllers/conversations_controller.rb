# frozen_string_literal: true

class ConversationsController < ApplicationController
  include Pagination

  def index
    @conversations = Current.user.conversations
    @conversations = params[:archive].present? ? @conversations.archived : @conversations.active
    if params[:search].present?
      matching_conversation_ids = Conversation::Participant
        .joins(:user)
        .where("users.name ILIKE ?", "%#{params[:search]}%")
        .select(:conversation_id)
      @conversations = @conversations.where(id: matching_conversation_ids)
    end
    @conversations = @conversations.page(page_number).per(3)
    render Views::Conversations::Index.new(user: Current.user, conversations: @conversations, search: params[:search].to_s, params: params)
  end

  def show
    @conversation = Current.user.conversations.find params[:id]
    @messages = @conversation.messages.page(page_number).per(3)
    render Views::Conversations::Show.new(user: Current.user, conversation: @conversation, messages: @messages, params: params)
  end

  def new
    redirect_to users_path, notice: "Find a user to start a conversation with."
  end
end
