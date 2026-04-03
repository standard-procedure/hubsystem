class MessagesController < ApplicationController
  include Pagination

  def index
    @messages = Current.user.messages.page(page_number)
    render Views::Messages::Index.new(user: Current.user, messages: @messages, search: params[:search].to_s, params: params)
  end

  def show
    @message = Current.user.messages.find params[:id]
    @conversation = @message.conversation
    @messages = @conversation.messages.page(page_number)
    render Views::Messages::Show.new(user: Current.user, message: @message, conversation: @conversation, messages: @messages, search: params[:search].to_s, params: params)
  end
end
