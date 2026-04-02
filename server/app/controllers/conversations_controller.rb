# frozen_string_literal: true

class ConversationsController < ApplicationController
  include Pagination

  def index
    @conversations = Current.user.conversations.page(page_number).per(3)
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
