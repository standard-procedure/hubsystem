# frozen_string_literal: true

require "rails_helper"

RSpec.describe NotificationsChannel, type: :channel do
  include ActionCable::TestHelper

  fixtures :users, :conversations, :conversation_participants, :conversation_messages

  let(:alice) { users(:alice) }
  let(:conversation) { conversations(:alpha) }

  describe "subscribing" do
    it "streams for the current user" do
      stub_connection current_user: alice
      subscribe
      expect(subscription).to be_confirmed
      expect(subscription).to have_stream_for(alice)
    end

    it "rejects when not authenticated" do
      stub_connection current_user: nil
      subscribe
      expect(subscription).to be_rejected
    end
  end

  describe "broadcasting" do
    it "delivers notifications to the user's stream" do
      NotificationsChannel.broadcast_to(alice, {
        "event" => "message.created",
        "conversation_id" => conversation.id,
        "message_id" => 1
      })

      stream = NotificationsChannel.broadcasting_for(alice)
      results = broadcasts(stream)
      expect(results.length).to eq(1)

      parsed = JSON.parse(results.first)
      expect(parsed["event"]).to eq("message.created")
      expect(parsed["conversation_id"]).to eq(conversation.id)
      expect(parsed["message_id"]).to eq(1)
    end

    it "does not deliver to other users" do
      bob = users(:bob)

      NotificationsChannel.broadcast_to(alice, {"event" => "message.created"})

      stream = NotificationsChannel.broadcasting_for(bob)
      expect(broadcasts(stream)).to be_empty
    end
  end
end
