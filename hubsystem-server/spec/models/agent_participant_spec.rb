require "rails_helper"

RSpec.describe AgentParticipant, type: :model do
  describe "validations" do
    subject { build(:agent_participant) }

    it { should validate_presence_of(:agent_class) }
    it { should validate_inclusion_of(:state).in_array(%w[awake napping]) }
  end

  describe "defaults" do
    it "defaults state to awake" do
      agent = create(:agent_participant)
      expect(agent.state).to eq("awake")
    end

    it "has default emotion parameters" do
      agent = create(:agent_participant)
      expect(agent.emotion_parameters["happy"]).to eq(75)
      expect(agent.emotion_parameters["focused"]).to eq(80)
    end
  end
end
