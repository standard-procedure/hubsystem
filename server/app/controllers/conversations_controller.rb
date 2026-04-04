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
    @conversations = @conversations.page(page_number)
    render Views::Conversations::Index.new(user: Current.user, conversations: @conversations, search: params[:search].to_s, params: params)
  end

  def show
    @conversation = Current.user.conversations.find params[:id]
    @messages = @conversation.messages.page(page_number)
    render Views::Conversations::Show.new(user: Current.user, conversation: @conversation, messages: @messages, params: params)
  end

  def new
    @users = if params[:q].present?
      User.active.in_order.search_by_name_or_uid(params[:q])
    else
      User.none
    end
    @selected_user = User.find_by(id: params[:with])
    render Views::Conversations::New.new(user: Current.user, users: @users, selected_user: @selected_user, query: params[:q].to_s)
  end

  def create
    participants = User.where(id: params[:conversation][:participant_ids])
    conversation = Current.user.start_conversation(
      message: params[:conversation][:message],
      subject: params[:conversation][:subject],
      with: participants
    )
    redirect_to conversation_path(conversation)
  rescue ActiveRecord::RecordInvalid => e
    @users = User.none
    @selected_user = participants.first
    render Views::Conversations::New.new(user: Current.user, users: @users, selected_user: @selected_user, query: ""), status: :unprocessable_entity
  end
end
