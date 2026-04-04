# frozen_string_literal: true

class Api::V1::ConversationsController < Api::V1::BaseController
  def index
    conversations = current_user.conversations
    conversations = params[:archived] ? conversations.archived : conversations.active
    if params[:search].present?
      matching_conversation_ids = Conversation::Participant
        .joins(:user)
        .where("users.name ILIKE ?", "%#{Conversation::Participant.sanitize_sql_like(params[:search])}%")
        .select(:conversation_id)
      conversations = conversations.where(id: matching_conversation_ids)
    end
    render json: conversations.page(page_number).map { |c| conversation_json(c) }
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
  end

  def update
    conversation = current_user.conversations.find(params[:id])
    conversation.update!(status: params.dig(:conversation, :status))
    render json: conversation_json(conversation)
  end

  private

  def mark_as_read(conversation)
    already_read_ids = current_user.message_readings.where(message_id: conversation.messages.select(:id)).pluck(:message_id)
    unread_ids = conversation.messages.where.not(sender: current_user).where.not(id: already_read_ids).pluck(:id)
    return if unread_ids.empty?
    Conversation::MessageReading.insert_all(unread_ids.map { |mid| {message_id: mid, user_id: current_user.id, created_at: Time.current, updated_at: Time.current} })
  end
end
