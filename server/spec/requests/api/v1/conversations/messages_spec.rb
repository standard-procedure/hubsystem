# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Conversation Messages", type: :request do
  fixtures :users, :user_sessions, :conversations, :conversation_participants,
    :conversation_messages, :conversation_message_readings,
    :oauth_applications, :oauth_access_tokens

  let(:token) { oauth_access_tokens(:alice).token }
  let(:headers) { {"Authorization" => "Bearer #{token}"} }
  let(:conversation) { conversations(:alpha) }

  describe "GET /api/v1/conversations/:conversation_id/messages" do
    it "returns messages for the conversation" do
      get api_v1_conversation_messages_path(conversation), headers: headers
      expect(response).to have_http_status(:ok)
      messages = JSON.parse(response.body)
      expect(messages).to be_an(Array)
      expect(messages.size).to eq(3)
    end

    it "includes sender, contents, and read status for each message" do
      get api_v1_conversation_messages_path(conversation), headers: headers
      message = JSON.parse(response.body).first
      expect(message).to include("id", "conversation_id", "sender", "contents", "read", "created_at")
      expect(message["sender"]).to include("id", "name", "uid")
    end

    it "returns messages in chronological order" do
      get api_v1_conversation_messages_path(conversation), headers: headers
      messages = JSON.parse(response.body)
      timestamps = messages.map { |m| m["created_at"] }
      expect(timestamps).to eq(timestamps.sort)
    end

    context "with search parameter" do
      it "filters messages by content" do
        get api_v1_conversation_messages_path(conversation, search: "Hello"), headers: headers
        expect(response).to have_http_status(:ok)
        messages = JSON.parse(response.body)
        expect(messages.all? { |m| m["contents"].downcase.include?("hello") }).to be true
      end
    end

    it "returns 404 for conversations the user is not part of" do
      bob_token = oauth_access_tokens(:bob).token
      bob_headers = {"Authorization" => "Bearer #{bob_token}"}
      get api_v1_conversation_messages_path(conversations(:beta)), headers: bob_headers
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/conversations/:conversation_id/messages" do
    it "creates a new message in the conversation" do
      expect {
        post api_v1_conversation_messages_path(conversation),
          params: {message: {contents: "A new message"}},
          headers: headers, as: :json
      }.to change(Conversation::Message, :count).by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["contents"]).to eq("A new message")
      expect(body).to include("id", "conversation_id", "sender", "contents", "read", "created_at")
      expect(body["sender"]).to include("id", "name", "uid")
    end

    it "returns 404 for archived conversations" do
      post api_v1_conversation_messages_path(conversations(:archived_chat)),
        params: {message: {contents: "Should fail"}},
        headers: headers, as: :json
      expect(response).to have_http_status(:not_found)
    end
  end
end
