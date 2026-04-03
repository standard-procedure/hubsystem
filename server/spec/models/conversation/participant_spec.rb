# frozen_string_literal: true

require "rails_helper"

RSpec.describe Conversation::Participant, type: :model do
  fixtures :users, :conversations, :conversation_participants

  describe "associations" do
    it "belongs to a conversation" do
      expect(conversation_participants(:alice_in_alpha).conversation).to eq(conversations(:alpha))
    end

    it "belongs to a user" do
      expect(conversation_participants(:alice_in_alpha).user).to eq(users(:alice))
    end
  end

  describe "participant_type enum" do
    it "defaults to member" do
      expect(Conversation::Participant.new.participant_type).to eq("member")
    end

    it "can be member" do
      expect(conversation_participants(:bob_in_alpha)).to be_member
    end

    it "can be admin" do
      expect(conversation_participants(:alice_in_alpha)).to be_admin
    end
  end

  describe "#to_s" do
    it "returns the participant_type as a string" do
      expect(conversation_participants(:alice_in_alpha).to_s).to eq("Alice Aardvark")
      expect(conversation_participants(:bob_in_alpha).to_s).to eq("Bob Badger")
    end
  end
end
