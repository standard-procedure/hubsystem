# frozen_string_literal: true

class Api::V1::TasksController < Api::V1::BaseController
  def index
    tasks = if params[:created]
      Task.created_by(current_user)
    else
      Task.assigned_to(current_user).open
    end
    render json: tasks.order(created_at: :desc).map { |t| task_json(t) }
  end

  def show
    task = Task.find(params[:id])
    render json: task_json(task, include_children: true)
  end

  def create
    task = Task.new(
      creator: current_user,
      subject: params[:task][:subject],
      description: params[:task][:description].presence,
      due_at: params[:task][:due_at].presence,
      schedule: params[:task][:schedule].presence,
      parent_id: params[:task][:parent_id].presence,
      assignee_id: params[:task][:assignee_id].presence
    )
    if task.save
      render json: task_json(task), status: :created
    else
      render json: {errors: task.errors.full_messages}, status: :unprocessable_content
    end
  end

  private

  def task_json(task, include_children: false)
    json = {
      id: task.id,
      subject: task.subject,
      description: task.description,
      status: task.status,
      blocked: task.blocked?,
      scheduled: task.scheduled?,
      schedule: task.schedule,
      due_at: task.due_at,
      completed_at: task.completed_at,
      tags: task.tags,
      creator: {id: task.creator.id, name: task.creator.name},
      assignee: task.assignee ? {id: task.assignee.id, name: task.assignee.name} : nil,
      parent_id: task.parent_id,
      created_at: task.created_at
    }
    if include_children
      json[:children] = task.children.map { |c| task_json(c) }
    end
    json
  end
end
