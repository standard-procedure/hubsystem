# frozen_string_literal: true

class TaskCancellationsController < ApplicationController
  def create
    @task = Task.find(params[:task_id])
    @task.cancel!
    redirect_to tasks_path
  end
end
