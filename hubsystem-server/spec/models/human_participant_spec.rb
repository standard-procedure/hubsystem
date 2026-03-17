require "rails_helper"

RSpec.describe HumanParticipant, type: :model do
  describe "token generation" do
    it "generates a token on create" do
      participant = create(:human_participant)
      expect(participant.token).to be_present
    end

    it "generates a unique token" do
      p1 = create(:human_participant)
      p2 = create(:human_participant, slug: "other-human")
      expect(p1.token).not_to eq(p2.token)
    end
  end
end
