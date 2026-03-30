# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synthetic::EmotionalProcessor, type: :module do
  fixtures :users, :humans, :synthetics, :synthetic_classes

  let(:bishop) { users(:bishop) }
  let(:alice) { users(:alice) }
  let(:bishop_synthetic) { synthetics(:bishop_synthetic) }
  let(:processor) { described_class.new(synthetic: bishop_synthetic) }
  let(:conversation) { Conversation.create!(initiator: alice, recipient: bishop, subject: "Test", status: :active) }

  def make_message(content)
    conversation.messages.create!(sender: alice, content: content)
  end

  describe "#process_incoming" do
    it "adjusts emotions based on incoming message" do
      stub_llm_response('{"joy": 10, "fear": -5}')
      deltas = processor.process_incoming(make_message("Great news!"))
      expect(deltas).to include("joy" => 10, "fear" => -5)
      bishop_synthetic.reload
      expect(bishop_synthetic.emotions["joy"]).to eq(60)
      expect(bishop_synthetic.emotions["fear"]).to eq(5)
    end

    it "returns empty deltas on parse error" do
      stub_llm_response("Not JSON")
      deltas = processor.process_incoming(make_message("Hello"))
      expect(deltas).to eq({})
    end
  end

  describe "#process_outgoing" do
    it "adjusts emotions based on outgoing response" do
      stub_llm_response('{"anticipation": 15, "sadness": -5}')
      deltas = processor.process_outgoing("I have a plan to help.")
      expect(deltas).to include("anticipation" => 15, "sadness" => -5)
      bishop_synthetic.reload
      expect(bishop_synthetic.emotions["anticipation"]).to eq(45)
      expect(bishop_synthetic.emotions["sadness"]).to eq(5)
    end
  end
end
