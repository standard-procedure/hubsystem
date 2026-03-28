# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Conversation lifecycle", type: :request do
  fixtures :users, :user_sessions, :conversations, :messages

  describe "POST /conversations/:id/acceptance" do
    it "accepts a conversation request as the recipient" do
      sign_in_as user_sessions(:alice_session)
      conversation = conversations(:bob_alice_requested)

      post conversation_acceptance_path(conversation)
      expect(conversation.reload).to be_active
      expect(response).to redirect_to(conversation_path(conversation))
    end
  end

  describe "POST /conversations/:id/rejection" do
    it "rejects a conversation request as the recipient" do
      sign_in_as user_sessions(:alice_session)
      conversation = conversations(:bob_alice_requested)

      post conversation_rejection_path(conversation)
      expect(conversation.reload).to be_closed
      expect(conversation.closed_at).to be_present
      expect(response).to redirect_to(conversations_path)
    end
  end

  describe "POST /conversations/:id/closure" do
    it "closes an active conversation" do
      sign_in_as user_sessions(:alice_session)
      conversation = conversations(:alice_charlie_active)

      post conversation_closure_path(conversation)
      expect(conversation.reload).to be_closed
      expect(conversation.closed_at).to be_present
      expect(response).to redirect_to(conversations_path)
    end
  end

  describe "GET /conversations/:id/closure/new" do
    it "shows the closure confirmation page" do
      sign_in_as user_sessions(:alice_session)
      conversation = conversations(:alice_charlie_active)

      get new_conversation_closure_path(conversation)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Close Conversation")
    end
  end

  describe "POST /conversations/:id/messages" do
    it "creates a message in an active conversation" do
      sign_in_as user_sessions(:alice_session)
      conversation = conversations(:alice_charlie_active)

      expect {
        post conversation_messages_path(conversation), params: {message: {content: "New message"}}
      }.to change(Message, :count).by(1)

      message = Message.last
      expect(message.sender).to eq(users(:alice))
      expect(message.content).to eq("New message")
      expect(response).to redirect_to(conversation_path(conversation))
    end
  end
end
