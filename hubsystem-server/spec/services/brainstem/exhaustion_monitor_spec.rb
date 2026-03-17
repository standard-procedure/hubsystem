require "rails_helper"

RSpec.describe Brainstem::ExhaustionMonitor do
  let(:monitor) { described_class.new }

  describe "#check" do
    context "when agent exhaustion is below threshold (80)" do
      let(:agent) do
        create(:agent_participant, state: "awake",
               emotion_parameters: { "happy" => 75, "anxious" => 10, "focused" => 80,
                                     "exhausted" => 79, "irritated" => 10 })
      end

      it "does not change the agent state" do
        expect { monitor.check(agent) }.not_to change { agent.reload.state }
      end

      it "returns false" do
        expect(monitor.check(agent)).to eq(false)
      end
    end

    context "when agent exhaustion is at or above threshold (80)" do
      let(:agent) do
        create(:agent_participant, state: "awake",
               emotion_parameters: { "happy" => 75, "anxious" => 10, "focused" => 80,
                                     "exhausted" => 80, "irritated" => 10 })
      end

      it "sets agent state to napping" do
        monitor.check(agent)
        expect(agent.reload.state).to eq("napping")
      end

      it "enqueues a CompactionJob" do
        expect { monitor.check(agent) }.to have_enqueued_job(Brainstem::CompactionJob)
          .with(agent.id)
      end

      it "returns true" do
        expect(monitor.check(agent)).to eq(true)
      end
    end

    context "when exhaustion is exactly 100" do
      let(:agent) do
        create(:agent_participant, state: "awake",
               emotion_parameters: { "happy" => 50, "anxious" => 50, "focused" => 50,
                                     "exhausted" => 100, "irritated" => 50 })
      end

      it "sets agent to napping" do
        monitor.check(agent)
        expect(agent.reload.state).to eq("napping")
      end
    end
  end
end
