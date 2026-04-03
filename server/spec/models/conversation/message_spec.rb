# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversation::Message, type: :model do
  fixtures :users, :conversations, :conversation_participants, :conversation_messages

  describe "associations" do
    it "belongs to a conversation" do
      expect(conversation_messages(:alice_hello).conversation).to eq(conversations(:alpha))
    end

    it "belongs to a sender" do
      expect(conversation_messages(:alice_hello).sender).to eq(users(:alice))
    end
  end

  describe "validations" do
    it "rejects a sender who is not a participant in the conversation" do
      message = Conversation::Message.new(
        conversation: conversations(:alpha),
        sender: users(:dave),
        contents: "Sneaky message"
      )
      expect(message).not_to be_valid
      expect(message.errors[:sender]).to be_present
    end

    it "accepts a sender who is a participant" do
      message = Conversation::Message.new(
        conversation: conversations(:alpha),
        sender: users(:alice),
        contents: "Valid message"
      )
      expect(message).to be_valid
    end
  end

  describe "#excerpt" do
    it "returns the first line of multi-line contents" do
      expect(conversation_messages(:alice_multiline).excerpt).to eq("First line")
    end

    it "returns the full contents when single-line" do
      expect(conversation_messages(:alice_hello).excerpt).to eq("Hello everyone")
    end
  end

  describe "#to_s" do
    it "returns the excerpt" do
      expect(conversation_messages(:alice_hello).to_s).to eq("Hello everyone")
    end
  end

  describe "#send_reply" do
    it "creates a new message in the same conversation" do
      expect {
        conversation_messages(:alice_hello).send_reply(sender: users(:bob), contents: "Reply!")
      }.to change(Conversation::Message, :count).by(1)
    end

    it "sets the sender and contents on the reply" do
      reply = conversation_messages(:alice_hello).send_reply(sender: users(:bob), contents: "Reply!")
      expect(reply.sender).to eq(users(:bob))
      expect(reply.contents).to eq("Reply!")
      expect(reply.conversation).to eq(conversations(:alpha))
    end
  end

  describe "HasTags" do
    it "finds messages by tag" do
      conversation_messages(:alice_hello).update!(tags: ["important"])
      expect(Conversation::Message.tagged_with("important")).to include(conversation_messages(:alice_hello))
      expect(Conversation::Message.tagged_with("important")).not_to include(conversation_messages(:bob_reply))
    end
  end

  describe "#read_by?" do
    fixtures :conversation_message_readings

    it "returns truthy when the user has read the message" do
      expect(conversation_messages(:bob_reply).read_by?(users(:alice))).to be_truthy
    end

    it "returns falsy when the user has not read the message" do
      expect(conversation_messages(:alice_hello).read_by?(users(:bob))).to be_falsy
    end
  end

  describe "#embeddable_text" do
    it "returns the contents as a string" do
      expect(conversation_messages(:alice_hello).embeddable_text).to eq("Hello everyone")
    end
  end

  describe "#embedding_content_changed?" do
    it "returns true when contents has changed" do
      message = conversation_messages(:alice_hello)
      message.contents = "Updated"
      expect(message.embedding_content_changed?).to be true
    end

    it "returns false when contents has not changed" do
      expect(conversation_messages(:alice_hello).embedding_content_changed?).to be false
    end
  end

  describe "HasStatusBadge" do
    it "exposes the status_badge enum" do
      expect(conversation_messages(:alice_hello)).to be_online
      expect(conversation_messages(:alice_multiline)).to be_offline
    end
  end
end
