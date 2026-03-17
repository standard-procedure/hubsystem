class ConversationsController < ApplicationController
  before_action :authenticate_participant!

  def create
    conversation = Conversation.new(subject: conversation_params[:subject])

    if conversation_params[:participant_slugs].present?
      # CLI format: participant_slugs + initial_message
      recipients = Participant.where(slug: conversation_params[:participant_slugs])
      if recipients.empty?
        return render json: { error: "No participants found for given slugs" }, status: :unprocessable_entity
      end

      message = conversation.messages.build(
        from: @current_participant,
        to: recipients.first,
        subject: conversation_params[:subject]
      )
      message.parts.build(
        content_type: "text/plain",
        body: conversation_params[:initial_message] || "",
        position: 0
      )

      conversation.conversation_memberships.build(participant: @current_participant)
      recipients.each do |recipient|
        conversation.conversation_memberships.build(participant: recipient) unless recipient == @current_participant
      end
    else
      # Original format: message.to_id + parts
      message_attrs = conversation_params[:message]
      parts_attrs = message_attrs&.dig(:parts) || []

      message = conversation.messages.build(
        from: @current_participant,
        subject: message_attrs&.dig(:subject)
      )

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
      :initial_message,
      participant_slugs: [],
      message: [:subject, :to_id, parts: [:content_type, :body, :channel_hint]]
    )
  end
end
