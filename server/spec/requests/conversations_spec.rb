# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Conversations", type: :request do
  fixtures :users, :humans, :synthetics, :synthetic_classes, :user_sessions, :conversations, :messages

  before { sign_in_as user_sessions(:alice_session) }

  describe "GET /conversations" do
    it "returns active conversations" do
      get conversations_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Catch up")
      expect(response.body).to include("Project update")
    end

    it "returns archived conversations when archived param is present" do
      conversations(:alice_charlie_active).update!(status: :closed, closed_at: Time.current)
      get conversations_path(archived: true)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Project update")
    end

    it "highlights conversation requests" do
      get conversations_path
      expect(response.body).to include("Pending request")
    end
  end

  describe "GET /conversations/:id" do
    it "shows the conversation with messages" do
      get conversation_path(conversations(:alice_charlie_active))
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Project update")
      expect(response.body).to include("Hey Charlie")
    end

    it "marks unread messages as read" do
      conversation = conversations(:alice_dave_active_unread)
      expect(conversation.messages.unread.count).to eq(1)

      get conversation_path(conversation)
      expect(conversation.messages.unread.count).to eq(0)
    end
  end

  describe "GET /conversations/new" do
    it "redirects to users page" do
      get new_conversation_path
      expect(response).to redirect_to(users_path)
    end
  end

  describe "POST /users/:user_id/conversations" do
    it "creates a conversation request" do
      expect {
        post user_conversations_path(users(:bob)), params: {conversation: {subject: "Hello"}}
      }.to change(Conversation, :count).by(1)

      conversation = Conversation.last
      expect(conversation).to be_requested
      expect(conversation.initiator).to eq(users(:alice))
      expect(conversation.recipient).to eq(users(:bob))
      expect(response).to redirect_to(conversation_path(conversation))
    end
  end

  describe "GET /messages" do
    it "redirects to conversations" do
      get messages_path
      expect(response).to redirect_to(conversations_path)
    end
  end
end
