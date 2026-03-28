# frozen_string_literal: true

class Views::Tasks::New < Views::Base
  include Phlex::Rails::Helpers::FormWith

  prop :user, User
  prop :parent, _Any?, default: nil

  def view_template
    title = @parent ? "New Subtask of: #{@parent.subject}" : "New Task"

    render Views::Layouts::Application.new(title: "HubSystem", user: @user, active_nav: :system) do
      render Components::Panel.new(title: title) do
        form_with url: tasks_path, method: :post do |form|
          Column gap: 12 do
            if @parent
              input type: "hidden", name: "task[parent_id]", value: @parent.id
            end
            Input name: "task[subject]", label: "Subject", placeholder: "What needs to be done?", type: "text", required: true
            Input name: "task[description]", label: "Description", placeholder: "Details (optional)", type: "text"
            Input name: "task[due_at]", label: "Due date", type: "datetime-local"
            Input name: "task[schedule]", label: "Schedule (cron)", placeholder: "e.g. 0 9 * * * for daily at 9am", type: "text"
            Row justify: "end" do
              Button label: "Create Task", variant: :primary
            end
          end
        end
      end
    end
  end
end
