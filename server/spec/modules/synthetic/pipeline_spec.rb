# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synthetic::Pipeline, type: :module do
  fixtures :users, :humans, :synthetics, :synthetic_classes

  let(:bishop) { users(:bishop) }
  let(:alice) { users(:alice) }
  let(:bishop_synthetic) { synthetics(:bishop_synthetic) }
  let(:pipeline) { described_class.new(synthetic: bishop_synthetic) }
  let(:conversation) { Conversation.create!(initiator: alice, recipient: bishop, subject: "Test", status: :active) }
  let(:message) { conversation.messages.create!(sender: alice, content: "Hello Bishop") }

  let(:mock_preprocessor) { instance_double(Synthetic::Preprocessor) }
  let(:mock_governor) { instance_double(Synthetic::Governor) }
  let(:mock_postprocessor) { instance_double(Synthetic::Postprocessor) }

  let(:mock_context) do
    context = bishop_synthetic.ensure_llm_context
    mock_response = instance_double(RubyLLM::Message, content: "I can help with that.")
    allow(context).to receive(:with_model).and_return(context)
    allow(context).to receive(:with_instructions).and_return(context)
    allow(context).to receive(:with_tools).and_return(context)
    allow(context).to receive(:ask).and_return(mock_response)
    allow(bishop_synthetic).to receive(:ensure_llm_context).and_return(context)
    context
  end

  before do
    allow(Synthetic::Preprocessor).to receive(:new).and_return(mock_preprocessor)
    allow(Synthetic::Governor).to receive(:new).and_return(mock_governor)
    allow(Synthetic::Postprocessor).to receive(:new).and_return(mock_postprocessor)
  end

  def stub_preprocessor(blocked: false, reason: "OK")
    allow(mock_preprocessor).to receive(:process)
      .and_return(Synthetic::Preprocessor::Result.new(blocked: blocked, reason: reason))
  end

  def stub_governor(approved: true, reason: "OK")
    allow(mock_governor).to receive(:process)
      .and_return(Synthetic::Governor::Result.new(approved: approved, reason: reason))
  end

  def stub_postprocessor
    allow(mock_postprocessor).to receive(:process)
  end

  describe "#process" do
    it "returns the LLM response for a safe message" do
      mock_context
      stub_preprocessor
      stub_governor
      stub_postprocessor

      result = pipeline.process(message)
      expect(result).to eq("I can help with that.")
    end

    it "returns nil for blocked messages" do
      stub_preprocessor(blocked: true, reason: "Prompt injection")

      result = pipeline.process(message)
      expect(result).to be_nil
    end

    it "replaces response when governor blocks it" do
      mock_context
      stub_preprocessor
      stub_governor(approved: false, reason: "Harmful content")
      stub_postprocessor

      result = pipeline.process(message)
      expect(result).to eq(Synthetic::Governor::REFUSAL_MESSAGE)
    end

    it "runs all four stages in order" do
      mock_context
      call_order = []

      allow(mock_preprocessor).to receive(:process) do
        call_order << :preprocess
        Synthetic::Preprocessor::Result.new(blocked: false, reason: "OK")
      end
      allow(mock_governor).to receive(:process) do
        call_order << :govern
        Synthetic::Governor::Result.new(approved: true, reason: "OK")
      end
      allow(mock_postprocessor).to receive(:process) do
        call_order << :postprocess
      end

      pipeline.process(message)
      expect(call_order).to eq([:preprocess, :govern, :postprocess])
    end

    it "triggers compaction via postprocessor" do
      mock_context
      stub_preprocessor
      stub_governor

      expect(mock_postprocessor).to receive(:process).with("I can help with that.")

      pipeline.process(message)
    end
  end
end
