# frozen_string_literal: true

module TaskSteps
  # --- Authentication ---

  step "I have logged in as Alice" do
    @alice = users(:alice)
    @alice_identity = user_identities(:alice_developer)
    OmniAuth.config.add_mock :developer, uid: @alice_identity.uid
    visit root_path
    click_on "Developer login"
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

  # --- Navigation ---

  step "I view my tasks" do
    visit tasks_path
  end

  step "I switch to the created tab" do
    click_on "Created by me"
  end

  step "I view that task" do
    visit task_path(@current_task)
  end

  step "I view the first assigned task" do
    click_on "Review the docs"
  end

  # --- Actions ---

  step "I create a new task called :subject" do |subject|
    click_on "New Task"
    fill_in "task[subject]", with: subject
    click_on "Create Task"
  end

  step "I create a new task called :subject with a due date" do |subject|
    click_on "New Task"
    fill_in "task[subject]", with: subject
    fill_in "task[due_at]", with: 1.day.from_now.strftime("%Y-%m-%dT%H:%M")
    click_on "Create Task"
  end

  step "I create a repeating task called :subject with schedule :schedule" do |subject, schedule|
    click_on "New Task"
    fill_in "task[subject]", with: subject
    fill_in "task[schedule]", with: schedule
    click_on "Create Task"
  end

  step "I add a subtask called :subject" do |subject|
    click_on "Add Subtask"
    fill_in "task[subject]", with: subject
    click_on "Create Task"
  end

  step "I assign the task to Bob" do
    choose "assignee_#{users(:bob).id}"
    click_on "Assign"
  end

  step "I complete the task" do
    click_on "Complete"
  end

  step "I cancel the task" do
    click_on "Cancel"
  end

  # --- Assertions ---

  step "I should see tasks assigned to me" do
    expect(page).to have_content("Review the docs")
    expect(page).to have_content("Fix the bug")
  end

  step "completed tasks should not be shown" do
    expect(page).not_to have_content("Done task")
  end

  step "I should see tasks I have created" do
    expect(page).to have_content("Bob should review")
  end

  step "I should see the task :subject" do |subject|
    visit tasks_path(created: true)
    expect(page).to have_content(subject)
  end

  step "the task should have a subtask called :subject" do |subject|
    visit task_path(@current_task)
    expect(page).to have_content(subject)
  end

  step "I should see the task :subject with its due date" do |subject|
    visit tasks_path(created: true)
    expect(page).to have_content(subject)
  end

  step "I should see the task :subject marked as repeating" do |subject|
    visit tasks_path(created: true)
    expect(page).to have_content(subject)
  end

  step "the task should be assigned to Bob" do
    expect(page).to have_content("Bob Badger")
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
    visit root_path
    expect(page).to have_css(".status-bar")
  end
end
