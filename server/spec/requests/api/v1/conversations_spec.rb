# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Conversations", type: :request do
  fixtures :users, :humans, :synthetics, :conversations, :messages, :oauth_applications, :oauth_access_tokens

  let(:alice) { users(:alice) }
  let(:bob) { users(:bob) }
  let(:headers) { {"Authorization" => "Bearer ALICE123"} }

  describe "GET /api/v1/conversations" do
    it "returns active conversations for the authenticated user" do
      get api_v1_conversations_path, headers: headers
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      subjects = data.map { |c| c["subject"] }
      expect(subjects).to include("Catch up")
      expect(subjects).to include("Project update")
    end

    it "returns 401 without a token" do
      get api_v1_conversations_path
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/conversations/:id" do
    it "returns conversation with messages" do
      conversation = conversations(:alice_charlie_active)
      get api_v1_conversation_path(conversation), headers: headers
      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["subject"]).to eq("Project update")
      expect(data["messages"]).to be_an(Array)
      expect(data["messages"].size).to eq(2)
    end
  end

  describe "POST /api/v1/conversations" do
    it "creates a conversation request" do
      expect {
        post api_v1_conversations_path, params: {conversation: {subject: "API test", recipient_id: bob.id}}, headers: headers
      }.to change(Conversation, :count).by(1)
      expect(response).to have_http_status(:created)
      data = JSON.parse(response.body)
      expect(data["subject"]).to eq("API test")
      expect(data["status"]).to eq("requested")
    end
  end

  describe "POST /api/v1/conversations/:id/acceptance" do
    it "accepts a conversation request" do
      conversation = conversations(:bob_alice_requested)
      post api_v1_conversation_acceptance_path(conversation), headers: headers
      expect(response).to have_http_status(:ok)
      expect(conversation.reload).to be_active
    end
  end

  describe "POST /api/v1/conversations/:id/rejection" do
    it "rejects a conversation request" do
      conversation = conversations(:bob_alice_requested)
      post api_v1_conversation_rejection_path(conversation), headers: headers
      expect(response).to have_http_status(:ok)
      expect(conversation.reload).to be_closed
    end
  end

  describe "POST /api/v1/conversations/:id/closure" do
    it "closes an active conversation" do
      conversation = conversations(:alice_charlie_active)
      post api_v1_conversation_closure_path(conversation), headers: headers
      expect(response).to have_http_status(:ok)
      expect(conversation.reload).to be_closed
    end
  end

  describe "POST /api/v1/conversations/:id/messages" do
    it "creates a message" do
      conversation = conversations(:alice_charlie_active)
      expect {
        post api_v1_conversation_messages_path(conversation), params: {message: {content: "Hello via API"}}, headers: headers
      }.to change(Message, :count).by(1)
      expect(response).to have_http_status(:created)
    end
  end
end
