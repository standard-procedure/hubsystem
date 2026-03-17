require "rails_helper"

RSpec.describe Brainstem::CompactionJob, type: :job do
  let(:agent) do
    create(:agent_participant, state: "napping",
           emotion_parameters: { "happy" => 60, "anxious" => 30, "focused" => 50,
                                 "exhausted" => 95, "irritated" => 20 })
  end

  describe "#perform" do
    it "resets exhaustion to 0" do
      described_class.perform_now(agent.id)
      expect(agent.reload.emotion_parameters["exhausted"]).to eq(0)
    end

    it "sets agent state to awake" do
      described_class.perform_now(agent.id)
      expect(agent.reload.state).to eq("awake")
    end

    it "preserves other emotion parameters" do
      described_class.perform_now(agent.id)
      params = agent.reload.emotion_parameters
      expect(params["happy"]).to eq(60)
      expect(params["anxious"]).to eq(30)
    end
  end
end
