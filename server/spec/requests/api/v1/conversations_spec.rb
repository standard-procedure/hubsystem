# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Conversations", type: :request do
  fixtures :users, :user_sessions, :conversations, :conversation_participants,
    :conversation_messages, :conversation_message_readings,
    :oauth_applications, :oauth_access_tokens

  let(:token) { oauth_access_tokens(:alice).token }
  let(:headers) { {"Authorization" => "Bearer #{token}"} }

  describe "GET /api/v1/conversations" do
    it "returns active conversations for the authenticated user" do
      get api_v1_conversations_path, headers: headers
      expect(response).to have_http_status(:ok)
      conversations = JSON.parse(response.body)
      expect(conversations).to be_an(Array)
      subjects = conversations.map { |c| c["subject"] }
      expect(subjects).to include("Alpha Team Chat", "Beta Project")
    end

    it "excludes archived conversations by default" do
      get api_v1_conversations_path, headers: headers
      conversations = JSON.parse(response.body)
      subjects = conversations.map { |c| c["subject"] }
      expect(subjects).not_to include("Old Discussion")
    end

    it "includes participants, status, and unread indicator" do
      get api_v1_conversations_path, headers: headers
      conversation = JSON.parse(response.body).first
      expect(conversation).to include("id", "subject", "status", "participants", "has_unread", "created_at", "updated_at")
      expect(conversation["participants"]).to be_an(Array)
      expect(conversation["participants"].first).to include("id", "name", "uid")
    end

    context "with archived parameter" do
      it "returns archived conversations" do
        get api_v1_conversations_path(archived: true), headers: headers
        expect(response).to have_http_status(:ok)
        conversations = JSON.parse(response.body)
        subjects = conversations.map { |c| c["subject"] }
        expect(subjects).to include("Old Discussion")
        expect(subjects).not_to include("Alpha Team Chat")
      end
    end

    context "with search parameter" do
      it "filters conversations by participant name" do
        get api_v1_conversations_path(search: "Charlie"), headers: headers
        expect(response).to have_http_status(:ok)
        conversations = JSON.parse(response.body)
        expect(conversations.size).to eq(1)
        expect(conversations.first["subject"]).to eq("Beta Project")
      end
    end

    it "returns 401 without a valid token" do
      get api_v1_conversations_path
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/conversations/:id" do
    it "returns the conversation with messages" do
      conversation = conversations(:alpha)
      get api_v1_conversation_path(conversation), headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["subject"]).to eq("Alpha Team Chat")
      expect(body["messages"]).to be_an(Array)
      expect(body["messages"].size).to eq(3)
    end

    it "includes full message details with sender and read status" do
      conversation = conversations(:alpha)
      get api_v1_conversation_path(conversation), headers: headers
      body = JSON.parse(response.body)
      message = body["messages"].first
      expect(message).to include("id", "sender", "contents", "read", "created_at")
      expect(message["sender"]).to include("id", "name", "uid")
    end

    it "marks unread messages from other senders as read" do
      alice = users(:alice)
      bob_reply = conversation_messages(:bob_reply)
      # Clear alice's reading of bob's reply to test mark-as-read
      alice.message_readings.find_by(message: bob_reply)&.destroy

      conversation = conversations(:alpha)
      get api_v1_conversation_path(conversation), headers: headers
      expect(bob_reply.reload.read_by?(alice)).to be_truthy
    end

    it "returns 404 for conversations the user is not part of" do
      bob_token = oauth_access_tokens(:bob).token
      bob_headers = {"Authorization" => "Bearer #{bob_token}"}
      get api_v1_conversation_path(conversations(:beta)), headers: bob_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/conversations" do
    it "creates a new conversation with a message" do
      expect {
        post api_v1_conversations_path, params: {
          conversation: {subject: "New Topic", message: "Hello there", participant_ids: [users(:dave).id]}
        }, headers: headers, as: :json
      }.to change(Conversation, :count).by(1)
        .and change(Conversation::Message, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["subject"]).to eq("New Topic")
    end

    it "returns 422 for invalid conversations" do
      post api_v1_conversations_path, params: {
        conversation: {subject: "", message: "", participant_ids: []}
      }, headers: headers, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
      body = JSON.parse(response.body)
      expect(body["errors"]).to be_an(Array)
    end
  end
end
