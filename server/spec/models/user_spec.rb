# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  fixtures :users, :user_sessions

  describe "validations" do
    it "requires a name" do
      user = User.new(name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it "requires a unique uid" do
      existing = users(:alice)
      user = User.new(name: "Someone", uid: existing.uid)
      expect(user).not_to be_valid
      expect(user.errors[:uid]).to include("has already been taken")
    end
  end

  describe "normalizations" do
    it "strips whitespace from name" do
      user = User.new(name: "  Padded Name  ")
      expect(user.name).to eq("Padded Name")
    end

    it "strips and downcases uid" do
      user = User.new(name: "Test", uid: "  ABC-123  ")
      expect(user.uid).to eq("abc-123")
    end
  end

  describe "#generate_uid" do
    it "generates a uid from name when blank" do
      user = User.create!(name: "New User")
      expect(user.uid).to match(/\Anew-user-\d+\z/)
    end

    it "does not overwrite an existing uid" do
      user = User.create!(name: "New User", uid: "custom-uid")
      expect(user.uid).to eq("custom-uid")
    end
  end

  describe "associations" do
    it "has many sessions" do
      alice = users(:alice)
      expect(alice.sessions).to include(user_sessions(:alice_session))
    end

    it "destroys dependent sessions" do
      alice = users(:alice)
      expect { alice.destroy }.to change(User::Session, :count).by(-1)
    end
  end

  describe "User::Conversations" do
    fixtures :conversations, :conversation_participants, :conversation_messages, :conversation_message_readings

    describe "associations" do
      it "has many sent_messages" do
        expect(users(:alice).sent_messages).to include(
          conversation_messages(:alice_hello),
          conversation_messages(:alice_multiline)
        )
      end

      it "has many conversation_memberships" do
        expect(users(:alice).conversation_memberships).to include(
          conversation_participants(:alice_in_alpha),
          conversation_participants(:alice_in_beta)
        )
      end

      it "has many conversations through memberships" do
        expect(users(:alice).conversations).to include(conversations(:alpha), conversations(:beta))
      end

      it "has many messages through conversations" do
        expect(users(:alice).messages).to include(
          conversation_messages(:alice_hello),
          conversation_messages(:bob_reply),
          conversation_messages(:alice_multiline)
        )
      end

      it "has many message_readings" do
        expect(users(:alice).message_readings).to include(conversation_message_readings(:alice_read_bob_reply))
      end

      it "has many read_messages through message_readings" do
        expect(users(:alice).read_messages).to include(conversation_messages(:bob_reply))
      end

      it "destroys dependent sent_messages" do
        expect { users(:bob).destroy }.to change(Conversation::Message, :count).by(-1)
      end

      it "destroys dependent conversation_memberships" do
        expect { users(:bob).destroy }.to change(Conversation::Participant, :count).by(-1)
      end

      it "destroys dependent message_readings" do
        expect { users(:alice).destroy }.to change(Conversation::MessageReading, :count).by(-6)
      end
    end

    describe "#unread_messages" do
      it "returns messages the user has not read" do
        alice = users(:alice)
        unread = alice.unread_messages
        expect(unread).to include(conversation_messages(:charlie_beta_msg))
        expect(unread).not_to include(conversation_messages(:bob_reply))
        expect(unread).not_to include(conversation_messages(:alice_hello))
      end

      it "orders by created_at ascending" do
        alice = users(:alice)
        unread = alice.unread_messages
        expect(unread).to eq(unread.sort_by(&:created_at))
      end
    end

    describe "#start_conversation" do
      it "creates a new conversation with the given message" do
        expect {
          users(:alice).start_conversation(message: "Hello Dave", with: [users(:dave)])
        }.to change(Conversation, :count).by(1)
          .and change(Conversation::Message, :count).by(1)
      end

      it "adds the caller as an admin participant" do
        conversation = users(:alice).start_conversation(message: "Hello Dave", with: [users(:dave)])
        participant = conversation.participants.find_by(user: users(:alice))
        expect(participant).to be_admin
      end

      it "adds other users as member participants" do
        conversation = users(:alice).start_conversation(message: "Hello Dave", with: [users(:dave)])
        participant = conversation.participants.find_by(user: users(:dave))
        expect(participant).to be_member
      end

      it "uses the first line of the message as subject when no subject given" do
        conversation = users(:alice).start_conversation(message: "Hello Dave\nHow are you?", with: [users(:dave)])
        expect(conversation.subject).to eq("Hello Dave")
      end

      it "uses the provided subject when given" do
        conversation = users(:alice).start_conversation(message: "Hello", subject: "Greetings", with: [users(:dave)])
        expect(conversation.subject).to eq("Greetings")
      end

      it "returns an existing conversation when one already involves the same users" do
        conversation1 = users(:alice).start_conversation(message: "First", with: [users(:dave)])
        conversation2 = users(:alice).start_conversation(message: "Second", with: [users(:dave)])
        expect(conversation2).to eq(conversation1)
      end

      it "works with no other participants" do
        conversation = users(:alice).start_conversation(message: "Note to self")
        expect(conversation).to be_persisted
        expect(conversation.users).to include(users(:alice))
      end
    end
  end
end
