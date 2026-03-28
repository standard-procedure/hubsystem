# frozen_string_literal: true

module ConversationSteps
  include ActiveSupport::Testing::TimeHelpers
  include Wait

  # --- Authentication ---

  step "I have logged in as Alice" do
    @alice = users(:alice)
    @alice_identity = user_identities(:alice_developer)
    OmniAuth.config.add_mock :developer, uid: @alice_identity.uid
    visit root_path
    click_on "Developer login"
  end

  # --- Setup / Given steps ---

  step "I have some existing conversations" do
    # Fixtures provide alice_charlie_active, alice_dave_active_unread, alice_bob_active
  end

  step "Bob has sent me a conversation request" do
    # Fixture bob_alice_requested covers this
  end

  step "I have an existing conversation with Bob" do
    # Fixture alice_bob_active covers this
  end

  # --- Navigation (browser-driven) ---

  step "I view the dashboard" do
    find("a[title='Dashboard']").click
  end

  step "I view my dashboard" do
    find("a[title='Dashboard']").click
  end

  step "I view my messages" do
    find("a[title='Messages']").click
  end

  step "I view my archived messages" do
    click_on "Archived"
  end

  step "I view the conversation request" do
    conversation = conversations(:bob_alice_requested)
    if page.has_css?(".status-matrix")
      find("a.matrix-cell[href='#{conversation_path(conversation)}']").click
    else
      click_on "Quick question"
    end
  end

  step "I click on the conversation with Bob" do
    conversation = conversations(:alice_bob_active)
    if page.has_css?(".status-matrix")
      find("a.matrix-cell[href='#{conversation_path(conversation)}']").click
    else
      click_on "Catch up"
    end
  end

  # --- Actions ---

  step "I ask Bob to start a conversation" do
    find("a[title='Messages']").click
    click_on "New Conversation"
    find("label", text: "Bob Badger").click
    fill_in "conversation[subject]", with: "Hi Bob"
    click_on "Send Request"
    @current_conversation = Conversation.last
  end

  step "Bob accepts the request" do
    conversation = @current_conversation || conversations(:bob_alice_requested)
    # Simulating Bob's action in the background
    conversation.update!(status: :active)
  end

  step "I send Bob a message" do
    conversation = @current_conversation || conversations(:alice_bob_active)
    # After Bob accepts, we need to refresh the page to see the message form
    wait_until { conversation.reload.active? }
    find("a[title='Messages']").click
    click_on conversation.subject
    fill_in "message[content]", with: "How are you?"
    click_on "Send"
  end

  step "Bob replies to the message" do
    conversation = @current_conversation || conversations(:alice_bob_active)
    conversation.messages.create!(sender: users(:bob), content: "I'm good, thanks!")
  end

  step "I reject the request" do
    click_on "Reject"
  end

  step "I close the conversation" do
    @current_conversation = conversations(:alice_bob_active)
    click_on "Close Conversation"
    click_on "Close Conversation"
  end

  # --- Assertions: Messages page ---

  step "I should see my existing conversations" do
    expect(page).to have_content("Catch up")
  end

  step "any conversations with unread messages should be highlighted in amber" do
    expect(page).to have_css(".conversation-item--unread")
  end

  step "my conversations with unread messages should be highlighted in amber" do
    expect(page).to have_css(".conversation-item--unread")
  end

  step "I should see the conversation request from Bob highlighted in red" do
    expect(page).to have_css(".conversation-item--request")
    expect(page).to have_content("Quick question")
  end

  step "I should see the previous messages between Bob and me" do
    expect(page).to have_content("Hey Bob, let's catch up")
    expect(page).to have_content("Sure, sounds good!")
  end

  step "I should not see the conversation with Bob" do
    expect(page).not_to have_content("Catch up")
  end

  step "I should see the conversation with Bob" do
    expect(page).to have_content("Catch up")
  end

  # --- Assertions: Dashboard ---

  step "I should see my existing conversations in a status matrix" do
    expect(page).to have_css(".status-matrix")
    expect(page).to have_css(".matrix-cell")
  end

  step "conversations with unread messages should be represented by an amber cell" do
    expect(page).to have_css(".matrix-cell--degraded")
  end

  step "my conversation request from Bob should be represented by a red cell" do
    expect(page).to have_css(".matrix-cell--critical")
  end

  step "the conversation with Bob should be represented by a greyed out cell" do
    expect(page).to have_css(".matrix-cell--offline")
  end

  step "the conversation with Bob should not be visible in the conversation matrix" do
    expect(page).not_to have_css(".matrix-cell--offline")
  end

  # --- Assertions: Conversation state ---

  step "Bob should receive my message" do
    conversation = @current_conversation || conversations(:alice_bob_active)
    wait_until { conversation.messages.where(sender: users(:alice)).where("content LIKE ?", "%How are you?%").exists? }
    expect(conversation.messages.where(sender: users(:alice)).last.content).to eq("How are you?")
  end

  step "I should receive Bob's message" do
    conversation = @current_conversation || conversations(:alice_bob_active)
    wait_until { conversation.messages.where(sender: users(:bob)).where("content LIKE ?", "%I'm good%").exists? }
    # Navigate to the conversation to see the new message
    find("a[title='Messages']").click
    click_on conversation.subject
    expect(page).to have_content("I'm good, thanks!")
  end

  step "Bob should receive my rejection" do
    conversation = conversations(:bob_alice_requested)
    wait_until { conversation.reload.closed? }
  end

  step "the conversation should be closed" do
    conversation = @current_conversation || conversations(:bob_alice_requested)
    wait_until { conversation.reload.closed? }
  end

  step "I return to my dashboard a day later" do
    travel_to 2.days.from_now
    find("a[title='Dashboard']").click
  end
end
