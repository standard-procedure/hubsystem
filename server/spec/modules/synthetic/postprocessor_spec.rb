# frozen_string_literal: true

require "rails_helper"

RSpec.describe Synthetic::Postprocessor, type: :module do
  fixtures :users, :humans, :synthetics, :synthetic_classes

  let(:bishop_synthetic) { synthetics(:bishop_synthetic) }
  let(:postprocessor) { described_class.new(synthetic: bishop_synthetic) }

  let(:mock_memory_processor) { instance_double(Synthetic::MemoryProcessor) }
  let(:mock_emotional_processor) { instance_double(Synthetic::EmotionalProcessor) }
  let(:mock_capacity_evaluator) { instance_double(Synthetic::CapacityEvaluator) }
  let(:mock_compactor) { instance_double(Synthetic::Compactor) }

  before do
    bishop_synthetic.ensure_llm_context
    allow(Synthetic::MemoryProcessor).to receive(:new).and_return(mock_memory_processor)
    allow(Synthetic::EmotionalProcessor).to receive(:new).and_return(mock_emotional_processor)
    allow(Synthetic::CapacityEvaluator).to receive(:new).and_return(mock_capacity_evaluator)
    allow(Synthetic::Compactor).to receive(:new).and_return(mock_compactor)
  end

  describe "#process" do
    it "runs memory and emotional processing" do
      memory_called = false
      emotion_called = false

      allow(mock_memory_processor).to receive(:process) do
        memory_called = true
        Synthetic::MemoryProcessor::Result.new(memories: [])
      end
      allow(mock_emotional_processor).to receive(:process_outgoing) do
        emotion_called = true
        {}
      end
      allow(mock_capacity_evaluator).to receive(:process)
        .and_return(Synthetic::CapacityEvaluator::Result.new(fatigue: 5, needs_compaction: false))

      postprocessor.process("Some response")
      expect(memory_called).to be true
      expect(emotion_called).to be true
    end

    it "triggers compaction when capacity is high" do
      allow(mock_memory_processor).to receive(:process)
        .and_return(Synthetic::MemoryProcessor::Result.new(memories: []))
      allow(mock_emotional_processor).to receive(:process_outgoing).and_return({})
      allow(mock_capacity_evaluator).to receive(:process)
        .and_return(Synthetic::CapacityEvaluator::Result.new(fatigue: 85, needs_compaction: true))

      expect(mock_compactor).to receive(:compact!)

      postprocessor.process("Response after many messages")
    end

    it "does not trigger compaction when fatigue is low" do
      allow(mock_memory_processor).to receive(:process)
        .and_return(Synthetic::MemoryProcessor::Result.new(memories: []))
      allow(mock_emotional_processor).to receive(:process_outgoing).and_return({})
      allow(mock_capacity_evaluator).to receive(:process)
        .and_return(Synthetic::CapacityEvaluator::Result.new(fatigue: 30, needs_compaction: false))

      expect(mock_compactor).not_to receive(:compact!)

      postprocessor.process("Normal response")
    end
  end
end
