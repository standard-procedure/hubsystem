# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synthetic::ConversationAcceptanceJob, type: :job do
  fixtures :users, :humans, :synthetics, :synthetic_classes

  let(:bishop) { users(:bishop) }
  let(:alice) { users(:alice) }

  describe "#perform" do
    it "accepts the conversation and responds to the subject" do
      conversation = Conversation.create!(initiator: alice, recipient: bishop, subject: "Can you help me?", status: :requested)

      pipeline = instance_double(Synthetic::Pipeline)
      allow(Synthetic::Pipeline).to receive(:new).with(synthetic: bishop.synthetic).and_return(pipeline)
      allow(pipeline).to receive(:process).with("Can you help me?").and_return("Of course!")

      described_class.perform_now(conversation, bishop)

      conversation.reload
      expect(conversation).to be_active
      # Records the subject as the first message
      expect(conversation.messages.count).to eq(1)
      expect(conversation.messages.first.sender).to eq(alice)
      expect(conversation.messages.first.content).to eq("Can you help me?")
    end

    it "does nothing for non-synthetic recipients" do
      conversation = Conversation.create!(initiator: alice, recipient: users(:bob), subject: "Hello", status: :requested)

      expect(Synthetic::Pipeline).not_to receive(:new)
      described_class.perform_now(conversation, users(:bob))

      expect(conversation.reload).to be_requested
    end

    it "does nothing for already active conversations" do
      conversation = Conversation.create!(initiator: alice, recipient: bishop, subject: "Test", status: :active)

      expect(Synthetic::Pipeline).not_to receive(:new)
      described_class.perform_now(conversation, bishop)
    end
  end
end
