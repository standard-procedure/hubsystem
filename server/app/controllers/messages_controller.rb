class MessagesController < ApplicationController
  def index
    @unread_messages = Current.user.unread_messages
    render Views::Messages::Index.new(user: Current.user, unread_messages: @unread_messages)
  end
end
