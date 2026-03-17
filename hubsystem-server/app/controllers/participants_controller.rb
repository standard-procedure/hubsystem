class ParticipantsController < ApplicationController
  before_action :authenticate_participant!

  def index
    participants = Participant.all
    render json: participants.map { |p| participant_json(p) }
  end

  def show
    participant = Participant.find(params[:id])
    render json: participant_json(participant).merge(
      emotion_parameters: participant.emotion_parameters,
      memory_count: participant.memories.count
    )
  end

  private

  def participant_json(p)
    {
      id: p.id,
      name: p.name,
      slug: p.slug,
      type: p.type,
      description: p.description,
      state: p.state
    }
  end
end
