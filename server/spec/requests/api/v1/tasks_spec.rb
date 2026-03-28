# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Tasks", type: :request do
  fixtures :users, :oauth_applications, :oauth_access_tokens

  let(:alice) { users(:alice) }
  let(:bob) { users(:bob) }
  let(:headers) { {"Authorization" => "Bearer ALICE123"} }

  describe "GET /api/v1/tasks" do
    it "returns tasks assigned to the authenticated user" do
      Task.create!(creator: bob, assignee: alice, subject: "API task")
      get api_v1_tasks_path, headers: headers
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data.first["subject"]).to eq("API task")
    end

    it "returns created tasks with created param" do
      Task.create!(creator: alice, subject: "Created task")
      get api_v1_tasks_path(created: true), headers: headers
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data.first["subject"]).to eq("Created task")
    end

    it "returns 401 without a token" do
      get api_v1_tasks_path
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/tasks/:id" do
    it "returns a task with children" do
      parent = Task.create!(creator: alice, subject: "Parent task")
      Task.create!(creator: alice, subject: "Child task", parent: parent)
      get api_v1_task_path(parent), headers: headers
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["subject"]).to eq("Parent task")
      expect(data["children"].size).to eq(1)
    end
  end

  describe "POST /api/v1/tasks" do
    it "creates a task" do
      expect {
        post api_v1_tasks_path, params: {task: {subject: "New API task"}}, headers: headers
      }.to change(Task, :count).by(1)
      expect(response).to have_http_status(:created)
      data = JSON.parse(response.body)
      expect(data["subject"]).to eq("New API task")
      expect(data["creator"]["name"]).to eq("Alice Aardvark")
    end

    it "creates a task with assignee and due date" do
      post api_v1_tasks_path, params: {task: {subject: "Assigned", assignee_id: bob.id, due_at: "2026-04-01T10:00:00Z"}}, headers: headers
      expect(response).to have_http_status(:created)
      data = JSON.parse(response.body)
      expect(data["assignee"]["name"]).to eq("Bob Badger")
      expect(data["due_at"]).to be_present
    end
  end

  describe "PATCH /api/v1/tasks/:id/assignment" do
    it "assigns a task" do
      task = Task.create!(creator: alice, subject: "Assign me")
      patch api_v1_task_assignment_path(task), params: {assignee_id: bob.id}, headers: headers
      expect(response).to have_http_status(:ok)
      expect(task.reload.assignee).to eq(bob)
    end
  end

  describe "POST /api/v1/tasks/:id/completion" do
    it "completes a task" do
      task = Task.create!(creator: alice, subject: "Complete me")
      post api_v1_task_completion_path(task), headers: headers
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["status"]).to eq("completed")
    end
  end

  describe "POST /api/v1/tasks/:id/cancellation" do
    it "cancels a task" do
      task = Task.create!(creator: alice, subject: "Cancel me")
      post api_v1_task_cancellation_path(task), headers: headers
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["status"]).to eq("cancelled")
    end
  end
end
