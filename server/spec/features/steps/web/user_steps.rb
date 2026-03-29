# frozen_string_literal: true

module UserSteps
  # --- Authentication (shared with conversation steps) ---

  step "I have logged in as Alice" do
    @alice = users(:alice)
    @alice_identity = user_identities(:alice_developer)
    OmniAuth.config.add_mock :developer, uid: @alice_identity.uid
    visit root_path
    click_on "Developer login"
  end

  # --- Navigation ---

  step "I view the users page" do
    visit users_path
  end

  step "I view Bishop's profile" do
    visit user_path(users(:bishop))
  end

  step "I view Bob's profile" do
    visit user_path(users(:bob))
  end

  # --- Actions ---

  step "I search for :query" do |query|
    fill_in "q", with: query
    click_on "Search"
  end

  step "I add a private note :content" do |content|
    click_on "Add Note"
    fill_in "note[content]", with: content
    choose "Private"
    click_on "Save Note"
  end

  step "I start a conversation with subject :subject" do |subject|
    click_on "Start Conversation"
    fill_in "conversation[subject]", with: subject
    click_on "Send Request"
  end

  # --- Assertions ---

  step "I should see a list of users" do
    expect(page).to have_content("Users")
    expect(page).to have_content("Alice Aardvark")
  end

  step "each user should show their status" do
    expect(page).to have_css(".status-dot")
  end

  step "I should see Bishop in the results" do
    expect(page).to have_content("Bishop")
  end

  step "I should not see Bob in the results" do
    expect(page).not_to have_content("Bob Badger")
  end

  step "I should see Bishop's details" do
    expect(page).to have_content("Bishop")
    expect(page).to have_content("Calm and methodical")
  end

  step "I should see Bishop is a Synthetic" do
    expect(page).to have_content("Synthetic")
    expect(page).to have_content("Standard Agent")
  end

  step "I should see my note on Bishop's profile" do
    expect(page).to have_content("Helpful for code review")
    expect(page).to have_content("Private")
  end

  step "a conversation request should be sent to Bob" do
    conversation = Conversation.last
    expect(conversation.initiator).to eq(users(:alice))
    expect(conversation.recipient).to eq(users(:bob))
    expect(conversation.subject).to eq("Quick question")
    expect(conversation).to be_requested
  end
end
