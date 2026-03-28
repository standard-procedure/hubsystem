# frozen_string_literal: true

module TaskSteps
  step "I have logged in as Alice" do
    @alice = users(:alice)
    @auth = auth_header(oauth_access_tokens(:alice))
  end

  step "there are tasks assigned to me" do
    @assigned_task = Task.create!(creator: users(:bob), assignee: @alice, subject: "Review the docs")
    Task.create!(creator: users(:bob), assignee: @alice, subject: "Fix the bug")
    Task.create!(creator: users(:bob), assignee: @alice, subject: "Done task", status: :completed, completed_at: 1.hour.ago)
  end

  step "I have created some tasks" do
    Task.create!(creator: @alice, assignee: users(:bob), subject: "Bob should review")
    Task.create!(creator: @alice, subject: "Unassigned task")
  end

  step "there is a task called :subject" do |subject|
    @current_task = Task.create!(creator: @alice, subject: subject)
  end

  step "there is an unassigned task called :subject" do |subject|
    @current_task = Task.create!(creator: @alice, subject: subject)
  end

  step "I view my tasks" do
    get api_v1_tasks_path, headers: @auth
    @listed_tasks = JSON.parse(response.body)
  end

  step "I switch to the created tab" do
    get api_v1_tasks_path(created: true), headers: @auth
    @listed_tasks = JSON.parse(response.body)
  end

  step "I view that task" do
    get api_v1_task_path(@current_task), headers: @auth
  end

  step "I view the first assigned task" do
    get api_v1_task_path(@assigned_task), headers: @auth
  end

  step "I create a new task called :subject" do |subject|
    post api_v1_tasks_path, params: {task: {subject: subject}}, headers: @auth
    data = JSON.parse(response.body)
    @created_task = Task.find(data["id"])
  end

  step "I create a new task called :subject with a due date" do |subject|
    post api_v1_tasks_path, params: {task: {subject: subject, due_at: 1.day.from_now.iso8601}}, headers: @auth
    data = JSON.parse(response.body)
    @created_task = Task.find(data["id"])
  end

  step "I create a repeating task called :subject with schedule :schedule" do |subject, schedule|
    post api_v1_tasks_path, params: {task: {subject: subject, schedule: schedule}}, headers: @auth
    data = JSON.parse(response.body)
    @created_task = Task.find(data["id"])
  end

  step "I add a subtask called :subject" do |subject|
    post api_v1_tasks_path, params: {task: {subject: subject, parent_id: @current_task.id}}, headers: @auth
  end

  step "I assign the task to Bob" do
    patch api_v1_task_assignment_path(@current_task), params: {assignee_id: users(:bob).id}, headers: @auth
  end

  step "I complete the task" do
    task = @assigned_task || @current_task
    post api_v1_task_completion_path(task), headers: @auth
  end

  step "I cancel the task" do
    task = @assigned_task || @current_task
    post api_v1_task_cancellation_path(task), headers: @auth
  end

  step "I should see tasks assigned to me" do
    subjects = @listed_tasks.map { |t| t["subject"] }
    expect(subjects).to include("Review the docs")
    expect(subjects).to include("Fix the bug")
  end

  step "completed tasks should not be shown" do
    subjects = @listed_tasks.map { |t| t["subject"] }
    expect(subjects).not_to include("Done task")
  end

  step "I should see tasks I have created" do
    subjects = @listed_tasks.map { |t| t["subject"] }
    expect(subjects).to include("Bob should review")
  end

  step "I should see the task :subject" do |subject|
    expect(Task.find_by(subject: subject)).to be_present
  end

  step "the task should have a subtask called :subject" do |subject|
    expect(@current_task.children.find_by(subject: subject)).to be_present
  end

  step "I should see the task :subject with its due date" do |subject|
    task = Task.find_by(subject: subject)
    expect(task.due_at).to be_present
  end

  step "I should see the task :subject marked as repeating" do |subject|
    task = Task.find_by(subject: subject)
    expect(task.schedule).to be_present
  end

  step "the task should be assigned to Bob" do
    expect(@current_task.reload.assignee).to eq(users(:bob))
  end

  step "the task should be marked as completed" do
    task = @assigned_task || @current_task
    expect(task.reload).to be_completed
  end

  step "the task should be marked as cancelled" do
    task = @assigned_task || @current_task
    expect(task.reload).to be_cancelled
  end

  step "I should see a task summary on the dashboard" do
    # Visual — not relevant for API
  end
end
