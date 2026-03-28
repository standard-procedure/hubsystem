# frozen_string_literal: true

class Api::V1::ConversationsController < Api::V1::BaseController
  def index
    conversations = if params[:archived]
      Conversation.involving(current_user).closed.order(closed_at: :desc)
    else
      Conversation.involving(current_user).where(status: [:requested, :active]).order(updated_at: :desc)
    end
    render json: conversations.map { |c| conversation_json(c) }
  end

  def show
    conversation = Conversation.involving(current_user).find(params[:id])
    conversation.messages.where.not(sender: current_user).unread.update_all(read_at: Time.current)
    render json: conversation_json(conversation, include_messages: true)
  end

  def create
    conversation = Conversation.new(
      subject: params[:conversation][:subject],
      initiator: current_user,
      recipient: User.find(params[:conversation][:recipient_id]),
      status: :requested
    )
    if conversation.save
      render json: conversation_json(conversation), status: :created
    else
      render json: {errors: conversation.errors.full_messages}, status: :unprocessable_entity
    end
  end

  private

  def conversation_json(conversation, include_messages: false)
    json = {
      id: conversation.id,
      subject: conversation.subject,
      status: conversation.status,
      initiator: user_json(conversation.initiator),
      recipient: user_json(conversation.recipient),
      has_unread: conversation.has_unread_messages_for?(current_user),
      created_at: conversation.created_at,
      updated_at: conversation.updated_at
    }
    if include_messages
      json[:messages] = conversation.messages.order(:created_at).map do |m|
        {id: m.id, sender: user_json(m.sender), content: m.content, read_at: m.read_at, created_at: m.created_at}
      end
    end
    json
  end

  def user_json(user)
    {id: user.id, name: user.name, uid: user.uid}
  end
end
