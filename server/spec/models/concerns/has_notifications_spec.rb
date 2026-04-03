# frozen_string_literal: true

require "rails_helper"

RSpec.describe HasNotifications, type: :model do
  include ActionCable::TestHelper

  fixtures :users, :conversations, :conversation_participants, :conversation_messages

  let(:alice) { users(:alice) }
  let(:bob) { users(:bob) }
  let(:conversation) { conversations(:alpha) }

  def broadcasts_for(user)
    stream = NotificationsChannel.broadcasting_for(user)
    broadcasts(stream).map { |raw| raw.is_a?(String) ? JSON.parse(raw) : raw }
  end

  describe "after creating a message" do
    it "broadcasts a message.created notification to all participants" do
      conversation.send_message(sender: alice, contents: "Hello")

      alice_notifications = broadcasts_for(alice)
      bob_notifications = broadcasts_for(bob)

      expect(alice_notifications.length).to eq(1)
      expect(bob_notifications.length).to eq(1)

      expect(alice_notifications.first).to include(
        "event" => "message.created",
        "conversation_id" => conversation.id
      )
      expect(alice_notifications.first["message_id"]).to be_present
    end

    it "does not broadcast to users outside the conversation" do
      charlie = users(:charlie)

      conversation.send_message(sender: alice, contents: "Hello")

      expect(broadcasts_for(charlie)).to be_empty
    end
  end

  describe "after updating a message" do
    it "broadcasts a message.updated notification" do
      message = conversation_messages(:alice_hello)
      message.update!(contents: "Edited content")

      notifications = broadcasts_for(alice)
      expect(notifications.last).to include("event" => "message.updated")
    end
  end
end
