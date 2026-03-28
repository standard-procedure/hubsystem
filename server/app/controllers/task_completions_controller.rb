# frozen_string_literal: true

class TaskCompletionsController < ApplicationController
  def create
    @task = Task.find(params[:task_id])
    @task.complete!
    redirect_to tasks_path
  end
end
