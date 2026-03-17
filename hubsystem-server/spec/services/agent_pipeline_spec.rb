require "rails_helper"

RSpec.describe AgentPipeline do
  let(:threat_evaluator) { instance_double(Amygdala::ThreatEvaluator) }
  let(:authorisation_checker) { instance_double(Amygdala::AuthorisationChecker) }
  let(:emotion_updater) { instance_double(Amygdala::EmotionUpdater) }
  let(:exhaustion_monitor) { instance_double(Brainstem::ExhaustionMonitor) }
  let(:memory_retriever) { instance_double(Hippocampus::MemoryRetriever) }
  let(:turn_processor) { instance_double(PrefrontalCortex::TurnProcessor) }
  let(:memory_writer) { instance_double(Hippocampus::MemoryWriter) }

  let(:pipeline) do
    described_class.new(
      threat_evaluator: threat_evaluator,
      authorisation_checker: authorisation_checker,
      emotion_updater: emotion_updater,
      exhaustion_monitor: exhaustion_monitor,
      memory_retriever: memory_retriever,
      turn_processor: turn_processor,
      memory_writer: memory_writer
    )
  end

  let(:agent) do
    create(:agent_participant, state: "awake",
           emotion_parameters: { "happy" => 75, "anxious" => 10, "focused" => 80,
                                 "exhausted" => 5, "irritated" => 10 })
  end
  let(:sender) { create(:human_participant) }
  let(:inbound_message) { create(:message, from: sender, to: agent) }
  let(:memories) { [] }
  let(:reply_message) { create(:message, from: agent, to: sender) }

  before do
    allow(authorisation_checker).to receive(:check).and_return(:allowed)
    allow(threat_evaluator).to receive(:evaluate).and_return(:safe)
    allow(exhaustion_monitor).to receive(:check).and_return(false)
    allow(memory_retriever).to receive(:retrieve).and_return(memories)
    allow(turn_processor).to receive(:process).and_return(reply_message)
    allow(memory_writer).to receive(:write)
    allow(emotion_updater).to receive(:update)
  end

  describe "#process" do
    context "when recipient is not an AgentParticipant" do
      let(:human_recipient) { create(:human_participant) }
      let(:message_to_human) { create(:message, from: sender, to: human_recipient) }

      it "returns nil without calling any pipeline steps" do
        expect(authorisation_checker).not_to receive(:check)
        result = pipeline.process(message_to_human)
        expect(result).to be_nil
      end
    end

    context "when authorisation is denied" do
      before { allow(authorisation_checker).to receive(:check).and_return(:denied) }

      it "returns nil" do
        expect(pipeline.process(inbound_message)).to be_nil
      end

      it "does not call the threat evaluator" do
        expect(threat_evaluator).not_to receive(:evaluate)
        pipeline.process(inbound_message)
      end
    end

    context "when message is flagged as do_not_process" do
      before { allow(threat_evaluator).to receive(:evaluate).and_return(:do_not_process) }

      it "returns nil" do
        expect(pipeline.process(inbound_message)).to be_nil
      end

      it "flags the message" do
        pipeline.process(inbound_message)
        expect(inbound_message.reload.flagged).to eq(true)
      end

      it "updates emotions with do_not_process direction" do
        expect(emotion_updater).to receive(:update)
          .with(agent, inbound_message, direction: :do_not_process)
        pipeline.process(inbound_message)
      end

      it "does not call the turn processor" do
        expect(turn_processor).not_to receive(:process)
        pipeline.process(inbound_message)
      end
    end

    context "when message is dodgy" do
      before { allow(threat_evaluator).to receive(:evaluate).and_return(:dodgy) }

      it "flags the message but continues processing" do
        pipeline.process(inbound_message)
        expect(inbound_message.reload.flagged).to eq(true)
      end

      it "still calls the turn processor" do
        expect(turn_processor).to receive(:process)
        pipeline.process(inbound_message)
      end
    end

    context "when agent is napping after pre-check" do
      before { allow(exhaustion_monitor).to receive(:check).and_return(true) }

      it "returns nil" do
        expect(pipeline.process(inbound_message)).to be_nil
      end

      it "does not call the memory retriever" do
        expect(memory_retriever).not_to receive(:retrieve)
        pipeline.process(inbound_message)
      end
    end

    context "for a complete successful pipeline run" do
      it "returns the reply message" do
        expect(pipeline.process(inbound_message)).to eq(reply_message)
      end

      it "retrieves memories for the agent" do
        expect(memory_retriever).to receive(:retrieve)
          .with(agent: agent, query: "Hello, world!")
        pipeline.process(inbound_message)
      end

      it "calls the turn processor" do
        expect(turn_processor).to receive(:process)
          .with(agent: agent, inbound_message: inbound_message,
                memories: memories, conversation: nil)
        pipeline.process(inbound_message)
      end

      it "writes memory with inbound message text" do
        expect(memory_writer).to receive(:write)
          .with(participant: agent, content: "Hello, world!")
        pipeline.process(inbound_message)
      end

      it "updates emotions for inbound direction" do
        expect(emotion_updater).to receive(:update)
          .with(agent, inbound_message, direction: :inbound)
        pipeline.process(inbound_message)
      end

      it "updates emotions for outbound direction" do
        expect(emotion_updater).to receive(:update)
          .with(agent, reply_message, direction: :outbound)
        pipeline.process(inbound_message)
      end

      it "runs exhaustion check after the turn" do
        expect(exhaustion_monitor).to receive(:check).twice
        pipeline.process(inbound_message)
      end
    end
  end
end
