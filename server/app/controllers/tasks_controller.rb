# frozen_string_literal: true

class TasksController < ApplicationController
  def index
    @tasks = if params[:created]
      Task.created_by(Current.user).order(created_at: :desc)
    else
      Task.assigned_to(Current.user).where.not(status: [:completed, :cancelled]).order(created_at: :desc)
    end
    render Views::Tasks::Index.new(user: Current.user, tasks: @tasks, created: params[:created].present?)
  end

  def show
    @task = Task.find(params[:id])
    render Views::Tasks::Show.new(user: Current.user, task: @task, users: User.where.not(id: Current.user.id).in_order)
  end

  def new
    @parent = Task.find_by(id: params[:parent_id])
    render Views::Tasks::New.new(user: Current.user, parent: @parent)
  end

  def create
    @task = Task.new(
      creator: Current.user,
      subject: params[:task][:subject],
      description: params[:task][:description].presence,
      due_at: params[:task][:due_at].presence,
      schedule: params[:task][:schedule].presence,
      parent_id: params[:task][:parent_id].presence
    )
    if @task.save
      redirect_to task_path(@task)
    else
      render Views::Tasks::New.new(user: Current.user, parent: @task.parent), status: :unprocessable_entity
    end
  end
end
