class MessagesController < ApplicationController
  include Pagination

  def index
    @messages = if params[:search].present?
      Current.user.messages.where("conversation_messages.contents ILIKE ?", "%#{params[:search]}%").page(page_number)
    else
      latest_ids = Current.user.unread_messages.group_by(&:conversation_id).map { |_, msgs| msgs.first.id }
      Current.user.messages.where(id: latest_ids).page(page_number)
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
