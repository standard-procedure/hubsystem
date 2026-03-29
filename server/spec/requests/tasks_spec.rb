# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tasks", type: :request do
  fixtures :users, :humans, :synthetics, :synthetic_classes, :user_sessions

  before { sign_in_as user_sessions(:alice_session) }

  let(:alice) { users(:alice) }
  let(:bob) { users(:bob) }

  describe "GET /tasks" do
    it "shows tasks assigned to the current user" do
      Task.create!(creator: bob, assignee: alice, subject: "My task")
      get tasks_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("My task")
    end

    it "shows created tasks when created param present" do
      Task.create!(creator: alice, assignee: bob, subject: "Created task")
      get tasks_path(created: true)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Created task")
    end
  end

  describe "GET /tasks/:id" do
    it "shows a task" do
      task = Task.create!(creator: alice, subject: "View me")
      get task_path(task)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("View me")
    end
  end

  describe "GET /tasks/new" do
    it "shows the new task form" do
      get new_task_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("New Task")
    end
  end

  describe "POST /tasks" do
    it "creates a task" do
      expect {
        post tasks_path, params: {task: {subject: "New task"}}
      }.to change(Task, :count).by(1)

      task = Task.last
      expect(task.creator).to eq(alice)
      expect(response).to redirect_to(task_path(task))
    end
  end

  describe "PATCH /tasks/:id/assignment" do
    it "assigns the task" do
      task = Task.create!(creator: alice, subject: "Assign me")
      patch task_assignment_path(task), params: {assignee_id: bob.id}
      expect(task.reload.assignee).to eq(bob)
      expect(response).to redirect_to(task_path(task))
    end
  end

  describe "POST /tasks/:id/completion" do
    it "completes the task" do
      task = Task.create!(creator: alice, subject: "Complete me")
      post task_completion_path(task)
      expect(task.reload).to be_completed
      expect(response).to redirect_to(tasks_path)
    end
  end

  describe "POST /tasks/:id/cancellation" do
    it "cancels the task" do
      task = Task.create!(creator: alice, subject: "Cancel me")
      post task_cancellation_path(task)
      expect(task.reload).to be_cancelled
      expect(response).to redirect_to(tasks_path)
    end
  end
end
