class MessagesController < ApplicationController
  include Pagination

  def index
    @messages = Current.user.messages.page(page_number)
    render Views::Messages::Index.new(user: Current.user, messages: @messages, search: params[:search].to_s, params: params)
  end
end
