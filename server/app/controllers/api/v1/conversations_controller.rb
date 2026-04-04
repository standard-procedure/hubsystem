# frozen_string_literal: true

class Api::V1::ConversationsController < Api::V1::BaseController
  def index
    conversations = current_user.conversations
    conversations = params[:archived] ? conversations.archived : conversations.active
    if params[:search].present?
      matching_conversation_ids = Conversation::Participant
        .joins(:user)
        .where("users.name ILIKE ?", "%#{params[:search]}%")
        .select(:conversation_id)
      conversations = conversations.where(id: matching_conversation_ids)
    end
    render json: conversations.map { |c| conversation_json(c) }
  end

  def show
    conversation = current_user.conversations.find(params[:id])
    mark_as_read(conversation)
    render json: conversation_json(conversation, include_messages: true)
  end

  def create
    conversation = current_user.start_conversation(
      message: params.dig(:conversation, :message),
      subject: params.dig(:conversation, :subject),
      with: User.where(id: Array.wrap(params.dig(:conversation, :participant_ids)))
    )
    render json: conversation_json(conversation), status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: e.record.errors.full_messages}, status: :unprocessable_entity
  end

  def update
    conversation = current_user.conversations.find(params[:id])
    conversation.update!(status: params.dig(:conversation, :status))
    render json: conversation_json(conversation)
  rescue ActiveRecord::RecordInvalid => e
    render json: {errors: e.record.errors.full_messages}, status: :unprocessable_entity
  end

  private

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

  def message_json(message)
    {
      id: message.id,
      sender: user_json(message.sender),
      contents: message.contents,
      read: message.read_by?(current_user).present?,
      created_at: message.created_at
    }
  end

  def user_json(user)
    {id: user.id, name: user.name, uid: user.uid}
  end

  def mark_as_read(conversation)
    conversation.messages.where.not(sender: current_user).each do |message|
      current_user.message_readings.find_or_create_by(message: message) unless message.read_by?(current_user)
    end
  end
end
