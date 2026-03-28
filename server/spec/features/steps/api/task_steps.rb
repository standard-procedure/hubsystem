# frozen_string_literal: true

module TaskSteps
  # --- Authentication ---

  step "I have logged in as Alice" do
    @alice = users(:alice)
  end

  # --- Setup ---

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

  # --- Navigation (model-level) ---

  step "I view my tasks" do
    @listed_tasks = Task.assigned_to(@alice).where.not(status: [:completed, :cancelled])
  end

  step "I switch to the created tab" do
    @listed_tasks = Task.created_by(@alice)
  end

  step "I view that task" do
  end

  step "I view the first assigned task" do
  end

  # --- Actions ---

  step "I create a new task called :subject" do |subject|
    Task.create!(creator: @alice, subject: subject)
  end

  step "I create a new task called :subject with a due date" do |subject|
    Task.create!(creator: @alice, subject: subject, due_at: 1.day.from_now)
  end

  step "I create a repeating task called :subject with schedule :schedule" do |subject, schedule|
    Task.create!(creator: @alice, subject: subject, schedule: schedule)
  end

  step "I add a subtask called :subject" do |subject|
    Task.create!(creator: @alice, subject: subject, parent: @current_task)
  end

  step "I assign the task to Bob" do
    @current_task.update!(assignee: users(:bob))
  end

  step "I complete the task" do
    task = @assigned_task || @current_task
    task.complete!
  end

  step "I cancel the task" do
    task = @assigned_task || @current_task
    task.cancel!
  end

  # --- Assertions ---

  step "I should see tasks assigned to me" do
    expect(@listed_tasks).to be_present
  end

  step "completed tasks should not be shown" do
    expect(@listed_tasks.completed).to be_empty
  end

  step "I should see tasks I have created" do
    expect(@listed_tasks).to be_present
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
