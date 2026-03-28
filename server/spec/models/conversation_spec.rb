# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversation, type: :model do
  fixtures :users, :conversations, :messages

  describe "associations" do
    it "belongs to an initiator" do
      conversation = conversations(:alice_charlie_active)
      expect(conversation.initiator).to eq(users(:alice))
    end

    it "belongs to a recipient" do
      conversation = conversations(:alice_charlie_active)
      expect(conversation.recipient).to eq(users(:charlie))
    end

    it "has many messages" do
      conversation = conversations(:alice_charlie_active)
      expect(conversation.messages.count).to eq(2)
    end

    it "destroys messages when destroyed" do
      conversation = conversations(:alice_charlie_active)
      expect { conversation.destroy }.to change(Message, :count).by(-2)
    end
  end

  describe "validations" do
    it "requires a subject" do
      conversation = Conversation.new(subject: nil, initiator: users(:alice), recipient: users(:bob))
      expect(conversation).not_to be_valid
      expect(conversation.errors[:subject]).to include("can't be blank")
    end

    it "requires initiator and recipient to be different" do
      conversation = Conversation.new(subject: "Self-talk", initiator: users(:alice), recipient: users(:alice))
      expect(conversation).not_to be_valid
      expect(conversation.errors[:recipient_id]).to include("must be different from initiator")
    end
  end

  describe "enum status" do
    it "defaults to requested" do
      conversation = Conversation.new
      expect(conversation).to be_requested
    end

    it "supports active status" do
      conversation = conversations(:alice_charlie_active)
      expect(conversation).to be_active
    end

    it "supports closed status" do
      conversation = conversations(:alice_charlie_active)
      conversation.update!(status: :closed, closed_at: Time.current)
      expect(conversation).to be_closed
    end
  end

  describe "scopes" do
    describe ".involving" do
      it "returns conversations where user is initiator or recipient" do
        results = Conversation.involving(users(:alice))
        expect(results).to include(conversations(:alice_charlie_active))
        expect(results).to include(conversations(:alice_dave_active_unread))
        expect(results).to include(conversations(:bob_alice_requested))
        expect(results).to include(conversations(:alice_bob_active))
      end

      it "does not return conversations the user is not part of" do
        results = Conversation.involving(users(:dave))
        expect(results).not_to include(conversations(:alice_charlie_active))
      end
    end

    describe ".recently_closed" do
      it "returns conversations closed within the last day" do
        conversation = conversations(:alice_charlie_active)
        conversation.update!(status: :closed, closed_at: 12.hours.ago)
        expect(Conversation.recently_closed).to include(conversation)
      end

      it "excludes conversations closed more than a day ago" do
        conversation = conversations(:alice_charlie_active)
        conversation.update!(status: :closed, closed_at: 2.days.ago)
        expect(Conversation.recently_closed).not_to include(conversation)
      end
    end
  end

  describe "#other_participant" do
    it "returns the recipient when called by the initiator" do
      conversation = conversations(:alice_charlie_active)
      expect(conversation.other_participant(users(:alice))).to eq(users(:charlie))
    end

    it "returns the initiator when called by the recipient" do
      conversation = conversations(:alice_charlie_active)
      expect(conversation.other_participant(users(:charlie))).to eq(users(:alice))
    end
  end

  describe "#has_unread_messages_for?" do
    it "returns true when there are unread messages from the other participant" do
      conversation = conversations(:alice_dave_active_unread)
      expect(conversation.has_unread_messages_for?(users(:alice))).to be true
    end

    it "returns false when all messages are read" do
      conversation = conversations(:alice_charlie_active)
      expect(conversation.has_unread_messages_for?(users(:alice))).to be false
    end

    it "returns false when unread messages are from the user themselves" do
      conversation = conversations(:alice_dave_active_unread)
      expect(conversation.has_unread_messages_for?(users(:dave))).to be false
    end
  end
end
