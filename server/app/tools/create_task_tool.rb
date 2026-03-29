# frozen_string_literal: true

class CreateTaskTool < RubyLLM::Tool
  description "Create a new task, optionally as a subtask of an existing task."

  param :subject, type: "string", desc: "Brief task title", required: true
  param :description, type: "string", desc: "Detailed description", required: false
  param :assignee_name, type: "string", desc: "Name or UID of user to assign to", required: false
  param :parent_id, type: "integer", desc: "ID of parent task (for subtasks)", required: false
  param :due_at, type: "string", desc: "Due date/time in ISO 8601 format", required: false
  param :tags, type: "string", desc: "Comma-separated tags", required: false

  def initialize(synthetic)
    @synthetic = synthetic
    super()
  end

  def execute(subject:, description: nil, assignee_name: nil, parent_id: nil, due_at: nil, tags: nil)
    assignee = find_assignee(assignee_name) if assignee_name.present?
    return "User '#{assignee_name}' not found." if assignee_name.present? && assignee.nil?

    parent = Task.find_by(id: parent_id) if parent_id.present?
    return "Parent task #{parent_id} not found." if parent_id.present? && parent.nil?

    tag_list = tags.present? ? tags.split(",").map(&:strip).reject(&:empty?) : []
    parsed_due = due_at.present? ? Time.iso8601(due_at) : nil

    task = Task.create!(
      creator: @synthetic,
      assignee: assignee,
      parent: parent,
      subject: subject,
      description: description,
      due_at: parsed_due,
      tags: tag_list
    )
    "Task created: [#{task.id}] #{task.subject}"
  rescue ArgumentError => e
    "Invalid date format: #{e.message}"
  end

  private

  def find_assignee(name)
    User.search_by_name_or_uid(name).first
  end
end
