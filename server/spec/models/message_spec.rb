# frozen_string_literal: true

require "rails_helper"

RSpec.describe Message, type: :model do
  fixtures :users, :conversations, :messages

  describe "associations" do
    it "belongs to a conversation" do
      message = messages(:alice_to_charlie)
      expect(message.conversation).to eq(conversations(:alice_charlie_active))
    end

    it "belongs to a sender" do
      message = messages(:alice_to_charlie)
      expect(message.sender).to eq(users(:alice))
    end
  end

  describe "validations" do
    it "requires content" do
      message = Message.new(conversation: conversations(:alice_charlie_active), sender: users(:alice), content: nil)
      expect(message).not_to be_valid
      expect(message.errors[:content]).to include("can't be blank")
    end
  end

  describe "scopes" do
    describe ".unread" do
      it "returns messages with no read_at" do
        unread = Message.unread
        expect(unread).to include(messages(:dave_to_alice_unread))
        expect(unread).not_to include(messages(:alice_to_charlie))
      end
    end
  end

  describe "#mark_as_read!" do
    it "sets read_at to current time" do
      message = messages(:dave_to_alice_unread)
      expect(message.read_at).to be_nil

      message.mark_as_read!
      expect(message.read_at).to be_within(1.second).of(Time.current)
    end

    it "does not overwrite an existing read_at" do
      message = messages(:alice_to_charlie)
      original_read_at = message.read_at

      message.mark_as_read!
      expect(message.read_at).to eq(original_read_at)
    end
  end
end
