# frozen_string_literal: true

class MessagesController < ApplicationController
  include Pagination

  def index
    @messages = if params[:search].present?
      Current.user.messages.where("conversation_messages.contents ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(params[:search])}%").page(page_number)
    else
      latest_per_conversation = Conversation::Message
        .where(conversation_id: Current.user.conversations.select(:id))
        .where.not(id: Current.user.message_readings.select(:message_id))
        .select("DISTINCT ON (conversation_id) id")
        .order(Arel.sql("conversation_id, created_at DESC"))
      Current.user.messages.where(id: latest_per_conversation).page(page_number)
    end
    render Views::Messages::Index.new(user: Current.user, messages: @messages, search: params[:search].to_s, params: params)
  end

  def show
    @message = Current.user.messages.find params[:id]
    @conversation = @message.conversation
    @messages = @conversation.messages.page(page_number)
    render Views::Messages::Show.new(user: Current.user, message: @message, conversation: @conversation, messages: @messages, search: params[:search].to_s, params: params)
  end
end
