class MessagesController < ApplicationController
  before_action :authenticate_participant!

  def create
    target = Participant.find(params[:participant_id])

    message = Message.new(
      from: @current_participant,
      to: target,
      subject: message_params[:subject]
    )

    parts_params = message_params[:parts] || []
    parts_params.each_with_index do |part, index|
      message.parts.build(
        content_type: part[:content_type],
        body: part[:body],
        channel_hint: part[:channel_hint],
        position: index
      )
    end

    if message.save
      render json: message_json(message), status: :created
    else
      render json: { errors: message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def index
    target = Participant.find(params[:participant_id])
    messages = target.inbox_messages.includes(:parts, :from)
    render json: messages.map { |m| message_json(m) }
  end

  private

  def message_params
    params.require(:message).permit(:subject, parts: [:content_type, :body, :channel_hint])
  end

  def message_json(message)
    {
      id: message.id,
      subject: message.subject,
      from_id: message.from_id,
      to_id: message.to_id,
      conversation_id: message.conversation_id,
      parts: message.parts.map { |p|
        {
          id: p.id,
          content_type: p.content_type,
          body: p.body,
          channel_hint: p.channel_hint,
          position: p.position
        }
      }
    }
  end
end
