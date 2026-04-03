# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Messages", type: :request do
  fixtures :users, :user_sessions, :conversations, :conversation_participants, :conversation_messages, :conversation_message_readings

  before { sign_in_as user_sessions(:alice_session) }

  describe "GET /messages" do
    it "returns the inbox" do
      get messages_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /messages/:id" do
    it "returns the message with conversation context" do
      message = conversation_messages(:alice_hello)
      get message_path(message)
      expect(response).to have_http_status(:ok)
    end

    it "renders the conversation's messages grid" do
      message = conversation_messages(:alice_hello)
      get message_path(message)
      expect(response.body).to include(ActionView::RecordIdentifier.dom_id(message, :grid_row))
    end

    it "renders the expanded content for the selected message" do
      message = conversation_messages(:alice_hello)
      get message_path(message)
      expect(response.body).to include("grid-row-expanded")
    end

    it "includes other messages from the same conversation" do
      message = conversation_messages(:alice_hello)
      other = conversation_messages(:bob_reply)
      get message_path(message)
      expect(response.body).to include(ActionView::RecordIdentifier.dom_id(other, :grid_row))
    end
  end
end
