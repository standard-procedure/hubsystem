# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversation::MessageReading, type: :model do
  fixtures :users, :conversations, :conversation_participants, :conversation_messages, :conversation_message_readings

  describe "associations" do
    it "belongs to a message" do
      expect(conversation_message_readings(:alice_read_bob_reply).message).to eq(conversation_messages(:bob_reply))
    end

    it "belongs to a user" do
      expect(conversation_message_readings(:alice_read_bob_reply).user).to eq(users(:alice))
    end
  end
end
