# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API V1 Messages", type: :request do
  fixtures :users, :user_sessions, :conversations, :conversation_participants,
    :conversation_messages, :conversation_message_readings,
    :oauth_applications, :oauth_access_tokens

  let(:token) { oauth_access_tokens(:alice).token }
  let(:headers) { {"Authorization" => "Bearer #{token}"} }

  describe "GET /api/v1/messages" do
    it "returns unread messages for the authenticated user" do
      get api_v1_messages_path, headers: headers
      expect(response).to have_http_status(:ok)
      messages = JSON.parse(response.body)
      expect(messages).to be_an(Array)
      expect(messages.map { |m| m["id"] }).to include(conversation_messages(:charlie_beta_msg).id)
    end

    it "excludes read messages by default" do
      get api_v1_messages_path, headers: headers
      messages = JSON.parse(response.body)
      ids = messages.map { |m| m["id"] }
      expect(ids).not_to include(conversation_messages(:bob_reply).id)
    end

    it "includes sender, contents, and read status for each message" do
      get api_v1_messages_path, headers: headers
      message = JSON.parse(response.body).first
      expect(message).to include("id", "conversation_id", "sender", "contents", "read", "created_at")
      expect(message["sender"]).to include("id", "name")
    end

    context "with search parameter" do
      it "searches all messages by content" do
        get api_v1_messages_path(search: "quarterly"), headers: headers
        expect(response).to have_http_status(:ok)
        messages = JSON.parse(response.body)
        expect(messages.any? { |m| m["contents"].include?("quarterly") }).to be true
      end
    end

    it "returns 401 without a valid token" do
      get api_v1_messages_path
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/messages/:id" do
    it "returns the message with its full conversation" do
      message = conversation_messages(:charlie_beta_msg)
      get api_v1_message_path(message), headers: headers
      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["message"]["id"]).to eq(message.id)
      expect(body["conversation"]["id"]).to eq(message.conversation_id)
      expect(body["conversation"]["subject"]).to eq("Beta Project")
      expect(body["conversation"]["messages"]).to be_an(Array)
    end

    it "includes all messages from the conversation" do
      message = conversation_messages(:alice_hello)
      get api_v1_message_path(message), headers: headers
      body = JSON.parse(response.body)
      conversation_message_ids = body["conversation"]["messages"].map { |m| m["id"] }
      expect(conversation_message_ids).to include(
        conversation_messages(:alice_hello).id,
        conversation_messages(:bob_reply).id,
        conversation_messages(:alice_multiline).id
      )
    end

    it "returns 404 for messages in conversations the user is not part of" do
      bob_token = oauth_access_tokens(:bob).token
      bob_headers = {"Authorization" => "Bearer #{bob_token}"}
      message = conversation_messages(:charlie_beta_msg)
      get api_v1_message_path(message), headers: bob_headers
      expect(response).to have_http_status(:not_found)
    end
  end
end
