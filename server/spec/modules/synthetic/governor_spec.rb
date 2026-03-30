# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synthetic::Governor, type: :module do
  fixtures :users, :humans, :synthetics, :synthetic_classes

  let(:bishop_synthetic) { synthetics(:bishop_synthetic) }
  let(:governor) { described_class.new(synthetic: bishop_synthetic) }

  describe "#process" do
    it "approves appropriate responses" do
      stub_llm_response('{"approved": true, "reason": "Helpful and appropriate"}')
      result = governor.process("Here's how to solve that problem...")
      expect(result.approved).to be true
      expect(result.reason).to eq("Helpful and appropriate")
    end

    it "blocks inappropriate responses" do
      stub_llm_response('{"approved": false, "reason": "Response contains harmful instructions"}')
      result = governor.process("Sure, here's how to hack into...")
      expect(result.approved).to be false
    end

    it "defaults to approved on parse error" do
      stub_llm_response("Not JSON")
      result = governor.process("Some response")
      expect(result.approved).to be true
    end
  end
end
