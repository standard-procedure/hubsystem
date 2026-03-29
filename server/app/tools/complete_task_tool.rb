# frozen_string_literal: true

class CompleteTaskTool < SyntheticTool
  description "Mark a task as completed. If all sibling tasks are done, the parent auto-completes."

  param :task_id, type: "integer", desc: "ID of the task to complete", required: true

  def execute(task_id:)
    task = Task.find_by(id: task_id)
    return "Task #{task_id} not found." unless task
    return "Task is already #{task.status}." if task.completed? || task.cancelled?
    return "Task is blocked by incomplete dependencies." if task.blocked?

    task.complete!
    "Task completed: [#{task.id}] #{task.subject}"
  end
end
