# frozen_string_literal: true

class TaskAssignmentsController < ApplicationController
  def update
    @task = Task.find(params[:task_id])
    assignee = User.find(params[:assignee_id])
    @task.update!(assignee: assignee)
    redirect_to task_path(@task)
  end
end
