# frozen_string_literal: true

class Api::V1::BaseController < ActionController::API
  include ErrorHandlers::Api
  include Pagination
  before_action :doorkeeper_authorize!

  private

  def current_user
    @current_user ||= User.find(doorkeeper_token.resource_owner_id)
  end

  def user_json(user)
    {id: user.id, name: user.name, uid: user.uid}
  end

  def message_json(message)
    {
      id: message.id,
      conversation_id: message.conversation_id,
      sender: user_json(message.sender),
      contents: message.contents,
      read: message.read_by?(current_user).present?,
      created_at: message.created_at
    }
  end

  def conversation_json(conversation, include_messages: false)
    json = {
      id: conversation.id,
      subject: conversation.subject,
      status: conversation.status,
      participants: conversation.users.map { |u| user_json(u) },
      has_unread: conversation.has_unread_messages_for?(current_user),
      created_at: conversation.created_at,
      updated_at: conversation.updated_at
    }
    if include_messages
      json[:messages] = conversation.messages.order(:created_at).map { |m| message_json(m) }
    end
    json
  end
end
