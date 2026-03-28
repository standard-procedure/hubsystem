# frozen_string_literal: true

module ConversationSteps
  include ActiveSupport::Testing::TimeHelpers

  step "I have logged in as Alice" do
    @alice = users(:alice)
    @auth = auth_header(oauth_access_tokens(:alice))
  end

  step "I have some existing conversations" do
  end

  step "Bob has sent me a conversation request" do
  end

  step "I have an existing conversation with Bob" do
  end

  step "I view the dashboard" do
  end

  step "I view my dashboard" do
  end

  step "I view my messages" do
    get api_v1_conversations_path, headers: @auth
    @listed_conversations = JSON.parse(response.body)
  end

  step "I view my archived messages" do
    get api_v1_conversations_path(archived: true), headers: @auth
    @listed_conversations = JSON.parse(response.body)
  end

  step "I view the conversation request" do
    conversation = conversations(:bob_alice_requested)
    get api_v1_conversation_path(conversation), headers: @auth
  end

  step "I click on the conversation with Bob" do
    conversation = conversations(:alice_bob_active)
    get api_v1_conversation_path(conversation), headers: @auth
  end

  step "I ask Bob to start a conversation" do
    post api_v1_conversations_path,
      params: {conversation: {subject: "Hi Bob", recipient_id: users(:bob).id}},
      headers: @auth
    data = JSON.parse(response.body)
    @current_conversation = Conversation.find(data["id"])
  end

  step "Bob accepts the request" do
    conversation = @current_conversation || conversations(:bob_alice_requested)
    bob_auth = auth_header(oauth_access_tokens(:bob))
    post api_v1_conversation_acceptance_path(conversation), headers: bob_auth
  end

  step "I send Bob a message" do
    conversation = @current_conversation || conversations(:alice_bob_active)
    post api_v1_conversation_messages_path(conversation),
      params: {message: {content: "How are you?"}},
      headers: @auth
  end

  step "Bob replies to the message" do
    conversation = @current_conversation || conversations(:alice_bob_active)
    bob_auth = auth_header(oauth_access_tokens(:bob))
    post api_v1_conversation_messages_path(conversation),
      params: {message: {content: "I'm good, thanks!"}},
      headers: bob_auth
  end

  step "I reject the request" do
    conversation = conversations(:bob_alice_requested)
    post api_v1_conversation_rejection_path(conversation), headers: @auth
  end

  step "I close the conversation" do
    @current_conversation = conversations(:alice_bob_active)
    post api_v1_conversation_closure_path(@current_conversation), headers: @auth
  end

  step "I should see my existing conversations" do
    expect(@listed_conversations).to be_present
  end

  step "any conversations with unread messages should be highlighted in amber" do
    unread = @listed_conversations.select { |c| c["has_unread"] }
    expect(unread).to be_present
  end

  step "my conversations with unread messages should be highlighted in amber" do
    unread = @listed_conversations.select { |c| c["has_unread"] }
    expect(unread).to be_present
  end

  step "I should see the conversation request from Bob highlighted in red" do
    requests = @listed_conversations.select { |c| c["status"] == "requested" }
    expect(requests).to be_present
  end

  step "I should see the previous messages between Bob and me" do
    conversation = conversations(:alice_bob_active)
    get api_v1_conversation_messages_path(conversation), headers: @auth
    messages = JSON.parse(response.body)
    expect(messages.size).to be >= 2
  end

  step "I should not see the conversation with Bob" do
    get api_v1_conversations_path, headers: @auth
    data = JSON.parse(response.body)
    subjects = data.map { |c| c["subject"] }
    expect(subjects).not_to include("Catch up")
  end

  step "I should see the conversation with Bob" do
    get api_v1_conversations_path(archived: true), headers: @auth
    data = JSON.parse(response.body)
    subjects = data.map { |c| c["subject"] }
    expect(subjects).to include("Catch up")
  end

  step "I should see my existing conversations in a status matrix" do
  end

  step "conversations with unread messages should be represented by an amber cell" do
  end

  step "my conversation request from Bob should be represented by a red cell" do
  end

  step "the conversation with Bob should be represented by a greyed out cell" do
  end

  step "the conversation with Bob should not be visible in the conversation matrix" do
  end

  step "Bob should receive my message" do
    conversation = @current_conversation || conversations(:alice_bob_active)
    expect(conversation.messages.where(sender: @alice).last.content).to eq("How are you?")
  end

  step "I should receive Bob's message" do
    conversation = @current_conversation || conversations(:alice_bob_active)
    get api_v1_conversation_messages_path(conversation), headers: @auth
    messages = JSON.parse(response.body)
    contents = messages.map { |m| m["content"] }
    expect(contents).to include("I'm good, thanks!")
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
