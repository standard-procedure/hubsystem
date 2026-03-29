# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Task tools", type: :model do
  fixtures :users, :humans, :synthetics

  let(:alice) { users(:alice) }
  let(:bob) { users(:bob) }
  let(:bishop) { users(:bishop) }

  describe CreateTaskTool do
    let(:tool) { described_class.new(bishop) }

    it "creates a top-level task" do
      expect {
        result = tool.execute(subject: "Deploy app")
        expect(result).to include("Task created")
      }.to change(Task, :count).by(1)

      task = Task.last
      expect(task.creator).to eq(bishop)
      expect(task.subject).to eq("Deploy app")
    end

    it "creates a subtask" do
      parent = Task.create!(creator: bishop, subject: "Project")
      result = tool.execute(subject: "Subtask", parent_id: parent.id)
      expect(result).to include("Task created")
      expect(Task.last.parent).to eq(parent)
    end

    it "assigns to a user by name" do
      tool.execute(subject: "Review", assignee_name: "Alice")
      expect(Task.last.assignee).to eq(alice)
    end

    it "returns error for unknown assignee" do
      result = tool.execute(subject: "Nope", assignee_name: "Nobody")
      expect(result).to include("not found")
    end

    it "creates with tags and due date" do
      tool.execute(subject: "Tagged", tags: "ops, urgent", due_at: "2026-04-01T10:00:00Z")
      task = Task.last
      expect(task.tags).to eq(["ops", "urgent"])
      expect(task.due_at).to be_present
    end
  end

  describe AssignTaskTool do
    let(:tool) { described_class.new(bishop) }

    it "assigns a task to a user" do
      task = Task.create!(creator: bishop, subject: "Do it")
      result = tool.execute(task_id: task.id, assignee_name: "Bob")
      expect(result).to include("assigned to Bob Badger")
      expect(task.reload.assignee).to eq(bob)
    end

    it "returns error for unknown task" do
      result = tool.execute(task_id: 999999, assignee_name: "Bob")
      expect(result).to include("not found")
    end
  end

  describe CompleteTaskTool do
    let(:tool) { described_class.new(bishop) }

    it "completes a task" do
      task = Task.create!(creator: bishop, subject: "Finish")
      result = tool.execute(task_id: task.id)
      expect(result).to include("Task completed")
      expect(task.reload).to be_completed
    end

    it "refuses to complete a blocked task" do
      dep = Task.create!(creator: bishop, subject: "Prerequisite")
      task = Task.create!(creator: bishop, subject: "Blocked")
      task.dependencies << dep

      result = tool.execute(task_id: task.id)
      expect(result).to include("blocked")
      expect(task.reload).to be_pending
    end

    it "returns error for already completed task" do
      task = Task.create!(creator: bishop, subject: "Done", status: :completed, completed_at: Time.current)
      result = tool.execute(task_id: task.id)
      expect(result).to include("already completed")
    end
  end

  describe ListTasksTool do
    let(:tool) { described_class.new(bishop) }

    before do
      Task.create!(creator: bishop, subject: "Pending task", assignee: alice)
      Task.create!(creator: bishop, subject: "Done task", assignee: alice, status: :completed, completed_at: Time.current)
      Task.create!(creator: bishop, subject: "Bob's task", assignee: bob)
    end

    it "lists pending tasks by default" do
      result = tool.execute
      expect(result).to include("Pending task")
      expect(result).to include("Bob's task")
      expect(result).not_to include("Done task")
    end

    it "filters by assignee" do
      result = tool.execute(assignee_name: "Alice")
      expect(result).to include("Pending task")
      expect(result).not_to include("Bob's task")
    end

    it "filters by status" do
      result = tool.execute(status: "completed")
      expect(result).to include("Done task")
      expect(result).not_to include("Pending task")
    end

    it "returns no tasks message when empty" do
      result = tool.execute(status: "cancelled")
      expect(result).to eq("No tasks found.")
    end
  end
end
