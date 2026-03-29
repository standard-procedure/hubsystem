# frozen_string_literal: true

class Views::Tasks::Index < Views::Base
  prop :user, User
  prop :tasks, _Any
  prop :created, _Boolean, default: false

  def view_template
    render Views::Layouts::Application.new(title: "Tasks", return_href: root_path, user: @user, active_nav: :system) do
      render Components::Panel.new(title: "Tasks") do
        Navigation do |nav|
          nav.item label: "Assigned to me", active: !@created, href: tasks_path
          nav.item label: "Created by me", active: @created, href: tasks_path(created: true)
        end

        div class: "task-list" do
          if @tasks.any?
            @tasks.each { |task| render_task(task) }
          else
            p(class: "text-muted") { @created ? "No tasks created." : "No tasks assigned." }
          end
        end

        Row justify: "end" do
          Button label: "New Task", variant: :primary, tag: :a, href: new_task_path
        end
      end
    end
  end

  private

  def render_task(task)
    css = ["task-item"]
    css << "task-item--blocked" if task.blocked?
    css << "task-item--scheduled" if task.scheduled?

    a href: task_path(task), class: css.join(" ") do
      span(class: "task-subject") { task.subject }
      span(class: "task-assignee") { task.assignee&.name || "Unassigned" }
      span(class: "task-status") { task_status_label(task) }
    end
  end

  def task_status_label(task)
    label = task.status.capitalize
    label += " (repeating)" if task.scheduled?
    label += " (due: #{task.due_at.strftime("%Y-%m-%d %H:%M")})" if task.due_at.present?
    label
  end
end
