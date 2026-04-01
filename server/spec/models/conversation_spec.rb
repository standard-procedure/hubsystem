# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversation, type: :model do
  fixtures :users, :conversations, :conversation_participants, :conversation_messages

  describe "validations" do
    it "requires a subject" do
      expect(Conversation.new(subject: nil)).not_to be_valid
    end
  end

  describe "normalizations" do
    it "strips whitespace from subject" do
      expect(Conversation.new(subject: "  Hello  ").subject).to eq("Hello")
    end
  end

  describe "associations" do
    it "has many participants" do
      expect(conversations(:alpha).participants).to include(
        conversation_participants(:alice_in_alpha),
        conversation_participants(:bob_in_alpha)
      )
    end

    it "has many users through participants" do
      expect(conversations(:alpha).users).to include(users(:alice), users(:bob))
    end

    it "has many messages" do
      expect(conversations(:alpha).messages).to include(
        conversation_messages(:alice_hello),
        conversation_messages(:bob_reply)
      )
    end

    it "destroys dependent participants on deletion" do
      expect { conversations(:alpha).destroy }.to change(Conversation::Participant, :count).by(-2)
    end

    it "destroys dependent messages on deletion" do
      expect { conversations(:alpha).destroy }.to change(Conversation::Message, :count).by(-3)
    end
  end

  describe "status enum" do
    it "defaults to active" do
      expect(Conversation.new).to be_active
    end

    it "can be archived" do
      expect(conversations(:archived_chat)).to be_archived
    end
  end

  describe "#add" do
    it "adds a user as a participant" do
      expect { conversations(:beta).add(users(:dave)) }.to change(Conversation::Participant, :count).by(1)
    end

    it "defaults to member participant_type" do
      conversations(:beta).add(users(:dave))
      expect(conversations(:beta).participants.find_by(user: users(:dave))).to be_member
    end

    it "accepts a custom participant_type" do
      conversations(:beta).add(users(:dave), participant_type: :admin)
      expect(conversations(:beta).participants.find_by(user: users(:dave))).to be_admin
    end

    it "does not create a duplicate when the user is already a participant" do
      expect { conversations(:alpha).add(users(:alice)) }.not_to change(Conversation::Participant, :count)
    end
  end

  describe "#remove" do
    it "removes the user's participation" do
      expect { conversations(:alpha).remove(users(:bob)) }.to change(Conversation::Participant, :count).by(-1)
    end

    it "is a no-op when the user is not a participant" do
      expect { conversations(:alpha).remove(users(:dave)) }.not_to change(Conversation::Participant, :count)
    end
  end

  describe "#send_message" do
    it "creates a message in the conversation" do
      expect {
        conversations(:alpha).send_message(sender: users(:alice), contents: "Hello!")
      }.to change(Conversation::Message, :count).by(1)
    end

    it "sets sender and contents on the created message" do
      message = conversations(:alpha).send_message(sender: users(:alice), contents: "Test content")
      expect(message.sender).to eq(users(:alice))
      expect(message.contents).to eq("Test content")
    end
  end

  describe "HasTags" do
    it "finds conversations by tag" do
      conversations(:alpha).update!(tags: ["urgent"])
      expect(Conversation.tagged_with("urgent")).to include(conversations(:alpha))
      expect(Conversation.tagged_with("urgent")).not_to include(conversations(:beta))
    end
  end

  describe "HasStatusBadge" do
    it "exposes the status_badge enum" do
      expect(conversations(:alpha)).to be_online
      expect(conversations(:beta)).to be_offline
    end
  end
end
