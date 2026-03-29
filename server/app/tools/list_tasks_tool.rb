# frozen_string_literal: true

class ListTasksTool < RubyLLM::Tool
  description "List tasks, optionally filtered by status, assignee, or tags."

  param :status, type: "string", desc: "Filter by status: pending, in_progress, completed, cancelled, or all (default: pending)", required: false
  param :assignee_name, type: "string", desc: "Filter by assignee name", required: false
  param :tag, type: "string", desc: "Filter by tag", required: false
  param :limit, type: "integer", desc: "Maximum results (default 20)", required: false

  def initialize(synthetic)
    @synthetic = synthetic
    super()
  end

  def execute(status: "pending", assignee_name: nil, tag: nil, limit: 20)
    scope = Task.all
    scope = scope.where(status: status) unless status == "all"
    scope = scope.tagged_with(tag) if tag.present?

    if assignee_name.present?
      assignee = User.search_by_name_or_uid(assignee_name).first
      return "User '#{assignee_name}' not found." unless assignee
      scope = scope.assigned_to(assignee)
    end

    tasks = scope.order(created_at: :desc).limit([limit, 50].min)
    return "No tasks found." if tasks.empty?

    tasks.map do |t|
      assignee_text = t.assignee ? " → #{t.assignee.name}" : ""
      blocked_text = t.blocked? ? " [BLOCKED]" : ""
      due_text = t.due_at ? " (due: #{t.due_at.strftime("%Y-%m-%d %H:%M")})" : ""
      "- [#{t.id}] #{t.subject}#{assignee_text} (#{t.status})#{blocked_text}#{due_text}"
    end.join("\n")
  end
end
