# frozen_string_literal: true

class Api::V1::TaskCancellationsController < Api::V1::BaseController
  def create
    task = Task.find(params[:task_id])
    task.cancel!
    render json: {id: task.id, status: task.status, completed_at: task.completed_at}
  end
end
