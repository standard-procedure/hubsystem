# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synthetic::EmotionalProcessor, type: :module do
  fixtures :users, :humans, :synthetics

  let(:bishop) { users(:bishop) }
  let(:processor) { described_class.new(bishop) }

  describe "#process_incoming" do
    it "adjusts emotions based on incoming message" do
      stub_llm_response('{"joy": 10, "fear": -5}')
      deltas = processor.process_incoming("Great news!")
      expect(deltas).to include("joy" => 10, "fear" => -5)
      bishop.reload
      expect(bishop.emotions["joy"]).to eq(60)
      expect(bishop.emotions["fear"]).to eq(5)
    end

    it "returns empty deltas on parse error" do
      stub_llm_response("Not JSON")
      deltas = processor.process_incoming("Hello")
      expect(deltas).to eq({})
    end
  end

  describe "#process_outgoing" do
    it "adjusts emotions based on outgoing response" do
      stub_llm_response('{"anticipation": 15, "sadness": -5}')
      deltas = processor.process_outgoing("I have a plan to help.")
      expect(deltas).to include("anticipation" => 15, "sadness" => -5)
      bishop.reload
      expect(bishop.emotions["anticipation"]).to eq(45)
      expect(bishop.emotions["sadness"]).to eq(5)
    end
  end
end
