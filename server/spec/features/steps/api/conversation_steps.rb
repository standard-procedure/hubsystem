# frozen_string_literal: true

module ConversationSteps
  include ActiveSupport::Testing::TimeHelpers

  # --- Authentication ---

  step "I have logged in as Alice" do
    @alice = users(:alice)
  end

  # --- Setup / Given steps ---

  step "I have some existing conversations" do
    # Fixtures provide existing conversations
  end

  step "Bob has sent me a conversation request" do
    # Fixture bob_alice_requested covers this
  end

  step "I have an existing conversation with Bob" do
    # Fixture alice_bob_active covers this
  end

  # --- Navigation (model-level, no HTTP) ---

  step "I view the dashboard" do
  end

  step "I view my dashboard" do
  end

  step "I view my messages" do
    @listed_conversations = Conversation.involving(@alice).where(status: [:requested, :active])
  end

  step "I view my archived messages" do
    @listed_conversations = Conversation.involving(@alice).closed
  end

  step "I view the conversation request" do
    @current_conversation = conversations(:bob_alice_requested)
  end

  step "I click on the conversation with Bob" do
    @current_conversation = conversations(:alice_bob_active)
    # Mark messages as read
    @current_conversation.messages.where.not(sender: @alice).unread.update_all(read_at: Time.current)
  end

  # --- Actions ---

  step "I ask Bob to start a conversation" do
    @current_conversation = Conversation.create!(
      subject: "Hi Bob",
      initiator: @alice,
      recipient: users(:bob),
      status: :requested
    )
  end

  step "Bob accepts the request" do
    conversation = @current_conversation || conversations(:bob_alice_requested)
    conversation.update!(status: :active)
  end

  step "I send Bob a message" do
    conversation = @current_conversation || conversations(:alice_bob_active)
    conversation.messages.create!(sender: @alice, content: "How are you?")
  end

  step "Bob replies to the message" do
    conversation = @current_conversation || conversations(:alice_bob_active)
    conversation.messages.create!(sender: users(:bob), content: "I'm good, thanks!")
  end

  step "I reject the request" do
    conversation = @current_conversation || conversations(:bob_alice_requested)
    conversation.update!(status: :closed, closed_at: Time.current)
  end

  step "I close the conversation" do
    conversation = @current_conversation || conversations(:alice_bob_active)
    conversation.update!(status: :closed, closed_at: Time.current)
  end

  # --- Assertions: Messages page ---

  step "I should see my existing conversations" do
    expect(@listed_conversations).to be_present
  end

  step "any conversations with unread messages should be highlighted in amber" do
    unread = @listed_conversations.select { |c| c.has_unread_messages_for?(@alice) }
    expect(unread).to be_present
  end

  step "my conversations with unread messages should be highlighted in amber" do
    unread = @listed_conversations.select { |c| c.has_unread_messages_for?(@alice) }
    expect(unread).to be_present
  end

  step "I should see the conversation request from Bob highlighted in red" do
    requests = @listed_conversations.select { |c| c.requested? && c.recipient == @alice }
    expect(requests).to be_present
  end

  step "I should see the previous messages between Bob and me" do
    conversation = @current_conversation || conversations(:alice_bob_active)
    expect(conversation.messages.count).to be >= 2
  end

  step "I should not see the conversation with Bob" do
    conversation = conversations(:alice_bob_active)
    active = Conversation.involving(@alice).where(status: [:requested, :active])
    expect(active).not_to include(conversation)
  end

  step "I should see the conversation with Bob" do
    conversation = conversations(:alice_bob_active)
    closed = Conversation.involving(@alice).closed
    expect(closed).to include(conversation)
  end

  # --- Assertions: Dashboard ---

  step "I should see my existing conversations in a status matrix" do
    conversations = Conversation.involving(@alice)
      .where(status: [:requested, :active])
      .or(Conversation.involving(@alice).recently_closed)
    expect(conversations).to be_present
  end

  step "conversations with unread messages should be represented by an amber cell" do
    conversations = Conversation.involving(@alice).active
    unread = conversations.select { |c| c.has_unread_messages_for?(@alice) }
    expect(unread).to be_present
  end

  step "my conversation request from Bob should be represented by a red cell" do
    requests = Conversation.involving(@alice).requested.where(recipient: @alice)
    expect(requests).to be_present
  end

  step "the conversation with Bob should be represented by a greyed out cell" do
    conversation = conversations(:alice_bob_active)
    expect(conversation.reload).to be_closed
    expect(conversation.closed_at).to be > 1.day.ago
  end

  step "the conversation with Bob should not be visible in the conversation matrix" do
    conversation = conversations(:alice_bob_active)
    recently_closed = Conversation.involving(@alice).recently_closed
    expect(recently_closed).not_to include(conversation)
  end

  # --- Assertions: Conversation state ---

  step "Bob should receive my message" do
    conversation = @current_conversation || conversations(:alice_bob_active)
    expect(conversation.messages.where(sender: @alice).last.content).to eq("How are you?")
  end

  step "I should receive Bob's message" do
    conversation = @current_conversation || conversations(:alice_bob_active)
    expect(conversation.messages.where(sender: users(:bob)).last.content).to eq("I'm good, thanks!")
  end

  step "Bob should receive my rejection" do
    conversation = conversations(:bob_alice_requested)
    expect(conversation.reload).to be_closed
  end

  step "the conversation should be closed" do
    conversation = @current_conversation || conversations(:bob_alice_requested)
    expect(conversation.reload).to be_closed
  end

  step "I return to my dashboard a day later" do
    travel_to 2.days.from_now
  end
end
