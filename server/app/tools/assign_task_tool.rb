# frozen_string_literal: true

class AssignTaskTool < RubyLLM::Tool
  description "Assign a task to a user."

  param :task_id, type: "integer", desc: "ID of the task to assign", required: true
  param :assignee_name, type: "string", desc: "Name or UID of user to assign to", required: true

  def initialize(synthetic)
    @synthetic = synthetic
    super()
  end

  def execute(task_id:, assignee_name:)
    task = Task.find_by(id: task_id)
    return "Task #{task_id} not found." unless task

    assignee = User.search_by_name_or_uid(assignee_name).first
    return "User '#{assignee_name}' not found." unless assignee

    task.update!(assignee: assignee)
    "Task [#{task.id}] #{task.subject} assigned to #{assignee.name}"
  end
end
