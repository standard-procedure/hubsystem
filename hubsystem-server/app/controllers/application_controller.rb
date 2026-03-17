class ApplicationController < ActionController::API
  private

  def authenticate_participant!
    token = request.headers["X-Hub-Token"]
    @current_participant = HumanParticipant.find_by(token: token)
    render json: { error: "Unauthorized" }, status: :unauthorized unless @current_participant
  end
end
