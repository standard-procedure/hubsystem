# frozen_string_literal: true

class Api::V1::TaskAssignmentsController < Api::V1::BaseController
  def update
    task = Task.find(params[:task_id])
    assignee = User.find(params[:assignee_id])
    task.update!(assignee: assignee)
    render json: {id: task.id, assignee: {id: assignee.id, name: assignee.name}}
  end
end
