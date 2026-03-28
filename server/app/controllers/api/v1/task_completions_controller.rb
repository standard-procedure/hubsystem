# frozen_string_literal: true

class Api::V1::TaskCompletionsController < Api::V1::BaseController
  def create
    task = Task.find(params[:task_id])
    task.complete!
    render json: {id: task.id, status: task.status, completed_at: task.completed_at}
  end
end
