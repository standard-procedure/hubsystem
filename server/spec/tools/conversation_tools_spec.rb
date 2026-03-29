# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Conversation tools", type: :model do
  fixtures :users, :humans, :synthetics, :conversations, :messages

  let(:bishop) { users(:bishop) }
  let(:alice) { users(:alice) }

  describe ListConversationsTool do
    let(:tool) { described_class.new(alice) }

    it "lists conversations involving the user" do
      result = tool.execute
      expect(result).to include("Catch up")
      expect(result).to include("Project update")
    end

    it "filters by status" do
      result = tool.execute(status: "requested")
      expect(result).to include("Quick question")
      expect(result).not_to include("Catch up")
    end

    it "returns no conversations message when empty" do
      tool = described_class.new(bishop)
      result = tool.execute
      expect(result).to eq("No conversations found.")
    end
  end

  describe StartConversationTool do
    let(:tool) { described_class.new(bishop) }

    it "creates a conversation request" do
      expect {
        result = tool.execute(recipient_name: "Alice", subject: "Need help")
        expect(result).to include("Conversation request sent to Alice Aardvark")
      }.to change(Conversation, :count).by(1)

      conversation = Conversation.last
      expect(conversation.initiator).to eq(bishop)
      expect(conversation.recipient).to eq(alice)
      expect(conversation).to be_requested
    end

    it "returns error for unknown users" do
      result = tool.execute(recipient_name: "Nobody", subject: "Hello")
      expect(result).to include("not found")
    end

    it "prevents self-conversation" do
      result = tool.execute(recipient_name: "Bishop", subject: "Talking to myself")
      expect(result).to include("cannot start a conversation with yourself")
    end
  end

  describe SendMessageTool do
    let(:tool) { described_class.new(alice) }
    let(:conversation) { conversations(:alice_bob_active) }

    it "sends a message in an active conversation" do
      expect {
        result = tool.execute(conversation_id: conversation.id, content: "Hello from tool")
        expect(result).to include("Message sent")
      }.to change(Message, :count).by(1)

      message = Message.last
      expect(message.sender).to eq(alice)
      expect(message.content).to eq("Hello from tool")
    end

    it "returns error for non-active conversations" do
      requested = conversations(:bob_alice_requested)
      result = tool.execute(conversation_id: requested.id, content: "Hello")
      expect(result).to include("not active")
    end

    it "returns error for unknown conversations" do
      result = tool.execute(conversation_id: 999999, content: "Hello")
      expect(result).to include("not found")
    end
  end
end
