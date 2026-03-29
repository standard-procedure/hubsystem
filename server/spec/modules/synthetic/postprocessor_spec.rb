# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synthetic::Postprocessor, type: :module do
  fixtures :users

  let(:bishop) { users(:bishop) }
  let(:postprocessor) { described_class.new(bishop) }

  before { bishop.ensure_llm_context }

  describe "#process" do
    it "runs memory and emotional processing" do
      memory_called = false
      emotion_called = false

      allow_any_instance_of(Synthetic::MemoryProcessor).to receive(:process) do
        memory_called = true
        Synthetic::MemoryProcessor::Result.new(memories: [])
      end
      allow_any_instance_of(Synthetic::EmotionalProcessor).to receive(:process_outgoing) do
        emotion_called = true
        {}
      end
      allow_any_instance_of(Synthetic::CapacityEvaluator).to receive(:process)
        .and_return(Synthetic::CapacityEvaluator::Result.new(fatigue: 5, needs_compaction: false))

      postprocessor.process("Some response")
      expect(memory_called).to be true
      expect(emotion_called).to be true
    end

    it "triggers compaction when capacity is high" do
      allow_any_instance_of(Synthetic::MemoryProcessor).to receive(:process)
        .and_return(Synthetic::MemoryProcessor::Result.new(memories: []))
      allow_any_instance_of(Synthetic::EmotionalProcessor).to receive(:process_outgoing).and_return({})
      allow_any_instance_of(Synthetic::CapacityEvaluator).to receive(:process)
        .and_return(Synthetic::CapacityEvaluator::Result.new(fatigue: 85, needs_compaction: true))

      expect_any_instance_of(Synthetic::Compactor).to receive(:compact!)

      postprocessor.process("Response after many messages")
    end

    it "does not trigger compaction when fatigue is low" do
      allow_any_instance_of(Synthetic::MemoryProcessor).to receive(:process)
        .and_return(Synthetic::MemoryProcessor::Result.new(memories: []))
      allow_any_instance_of(Synthetic::EmotionalProcessor).to receive(:process_outgoing).and_return({})
      allow_any_instance_of(Synthetic::CapacityEvaluator).to receive(:process)
        .and_return(Synthetic::CapacityEvaluator::Result.new(fatigue: 30, needs_compaction: false))

      expect_any_instance_of(Synthetic::Compactor).not_to receive(:compact!)

      postprocessor.process("Normal response")
    end
  end
end
