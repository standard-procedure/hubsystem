# frozen_string_literal: true

class Views::Tasks::Show < Views::Base
  include Phlex::Rails::Helpers::FormWith

  prop :user, User
  prop :task, Task
  prop :users, _Any

  def view_template
    render Views::Layouts::Application.new(title: @task.subject, return_href: tasks_path, user: @user, active_nav: :system) do
      render Components::Panel.new(title: @task.subject) do
        render_details
        render_assignment
        render_children
        render_actions
      end
    end
  end

  private

  def render_details
    StatusBar do |status|
      status.item label: @task.status.capitalize, state: status_state
      status.item label: @task.assignee&.name || "Unassigned", state: :info
      if @task.due_at
        status.item label: "Due: #{@task.due_at.strftime("%Y-%m-%d %H:%M")}", state: :warning
      end
      if @task.scheduled?
        status.item label: "Repeating: #{@task.schedule}", state: :info
      end
      if @task.blocked?
        status.item label: "Blocked", state: :critical
      end
    end

    if @task.description.present?
      div(class: "task-description") { @task.description }
    end
  end

  def render_assignment
    return if @task.completed? || @task.cancelled?

    render Components::Panel.new(title: "Assignment") do
      form_with url: task_assignment_path(@task), method: :patch do |form|
        div class: "radio-group" do
          @users.each do |u|
            selected = @task.assignee_id == u.id
            input type: "radio", name: "assignee_id", value: u.id, id: "assignee_#{u.id}",
              checked: selected
            label(for: "assignee_#{u.id}") { u.name }
          end
        end
        Row justify: "end" do
          Button label: "Assign", variant: :primary
        end
      end
    end
  end

  def render_children
    return unless @task.children.any?

    div class: "task-list" do
      @task.children.each do |child|
        a href: task_path(child), class: "task-item" do
          span(class: "task-subject") { child.subject }
          span(class: "task-status") { child.status.capitalize }
        end
      end
    end
  end

  def render_actions
    Row gap: 8, justify: "end" do
      if @task.pending? || @task.in_progress?
        Button label: "Add Subtask", variant: :ghost, tag: :a, href: new_task_path(parent_id: @task.id)

        form_with url: task_completion_path(@task), method: :post do
          Button label: "Complete", variant: :primary
        end

        form_with url: task_cancellation_path(@task), method: :post do
          Button label: "Cancel", variant: :danger
        end
      end
    end
  end

  def status_state
    case @task.status
    when "pending" then :warning
    when "in_progress" then :info
    when "completed" then :nominal
    when "cancelled" then :offline
    end
  end
end
