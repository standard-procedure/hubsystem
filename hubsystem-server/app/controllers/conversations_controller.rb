class ConversationsController < ApplicationController
  before_action :authenticate_participant!

  def create
    conversation = Conversation.new(subject: conversation_params[:subject])

    message_attrs = conversation_params[:message]
    parts_attrs = message_attrs&.dig(:parts) || []

    message = conversation.messages.build(
      from: @current_participant,
      subject: message_attrs&.dig(:subject)
    )

    # to is required — must be specified
    to_participant = Participant.find_by(id: conversation_params.dig(:message, :to_id))
    return render json: { error: "to_id is required" }, status: :unprocessable_entity unless to_participant

    message.to = to_participant
    conversation.conversation_memberships.build(participant: @current_participant)
    conversation.conversation_memberships.build(participant: to_participant) unless to_participant == @current_participant

    parts_attrs.each_with_index do |part, index|
      message.parts.build(
        content_type: part[:content_type],
        body: part[:body],
        channel_hint: part[:channel_hint],
        position: index
      )
    end

    if conversation.save
      render json: {
        id: conversation.id,
        subject: conversation.subject
      }, status: :created
    else
      render json: { errors: conversation.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def messages
    conversation = Conversation.find(params[:id])

    unless conversation.participants.include?(@current_participant)
      return render json: { error: "Unauthorized" }, status: :unauthorized
    end

    msgs = conversation.messages.includes(:parts, :from, :to)
    render json: msgs.map { |m|
      {
        id: m.id,
        subject: m.subject,
        from_id: m.from_id,
        to_id: m.to_id,
        parts: m.parts.map { |p|
          {
            id: p.id,
            content_type: p.content_type,
            body: p.body,
            channel_hint: p.channel_hint,
            position: p.position
          }
        }
      }
    }
  end

  private

  def conversation_params
    params.require(:conversation).permit(
      :subject,
      message: [:subject, :to_id, parts: [:content_type, :body, :channel_hint]]
    )
  end
end
