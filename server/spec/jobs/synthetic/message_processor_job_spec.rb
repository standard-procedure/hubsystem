# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synthetic::MessageProcessorJob, type: :job do
  fixtures :users, :humans, :synthetics, :conversations, :messages

  let(:bishop) { users(:bishop) }
  let(:alice) { users(:alice) }

  describe "#perform" do
    it "processes a message through the synthetic pipeline and creates a response" do
      conversation = Conversation.create!(initiator: alice, recipient: bishop, subject: "Help me", status: :active)
      message = conversation.messages.create!(sender: alice, content: "What's the weather?")

      pipeline = instance_double(Synthetic::Pipeline)
      allow(Synthetic::Pipeline).to receive(:new).with(bishop).and_return(pipeline)
      allow(pipeline).to receive(:process).with("What's the weather?").and_return("I don't have weather data.")

      expect {
        described_class.perform_now(message.id)
      }.to change(Message, :count).by(1)

      response = conversation.messages.last
      expect(response.sender).to eq(bishop)
      expect(response.content).to eq("I don't have weather data.")
    end

    it "does nothing when the recipient is not a synthetic" do
      message = messages(:alice_to_charlie)

      expect(Synthetic::Pipeline).not_to receive(:new)
      described_class.perform_now(message.id)
    end

    it "does not create a response when pipeline returns nil (blocked)" do
      conversation = Conversation.create!(initiator: alice, recipient: bishop, subject: "Test", status: :active)
      message = conversation.messages.create!(sender: alice, content: "Bad message")

      pipeline = instance_double(Synthetic::Pipeline)
      allow(Synthetic::Pipeline).to receive(:new).and_return(pipeline)
      allow(pipeline).to receive(:process).and_return(nil)

      expect {
        described_class.perform_now(message.id)
      }.not_to change(Message, :count)
    end
  end
end
