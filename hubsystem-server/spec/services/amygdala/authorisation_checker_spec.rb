require "rails_helper"

RSpec.describe Amygdala::AuthorisationChecker do
  let(:checker) { described_class.new }
  let(:sender) { create(:human_participant) }
  let(:recipient) { create(:agent_participant) }

  describe "#check" do
    context "when recipient belongs to no groups" do
      it "returns :allowed" do
        expect(checker.check(sender, recipient)).to eq(:allowed)
      end
    end

    context "when recipient belongs to a group" do
      let(:group) { create(:group) }

      before do
        create(:security_pass, participant: recipient, group: group)
      end

      context "and sender has 'message' capability for that group" do
        before do
          create(:security_pass, participant: sender, group: group, capabilities: ["message"])
        end

        it "returns :allowed" do
          expect(checker.check(sender, recipient)).to eq(:allowed)
        end
      end

      context "and sender has no security pass for that group" do
        it "returns :denied" do
          expect(checker.check(sender, recipient)).to eq(:denied)
        end
      end

      context "and sender has a pass for the group but without 'message' capability" do
        before do
          create(:security_pass, participant: sender, group: group, capabilities: ["read"])
        end

        it "returns :denied" do
          expect(checker.check(sender, recipient)).to eq(:denied)
        end
      end

      context "and sender has 'message' capability for a different group" do
        let(:other_group) { create(:group) }

        before do
          create(:security_pass, participant: sender, group: other_group, capabilities: ["message"])
        end

        it "returns :denied" do
          expect(checker.check(sender, recipient)).to eq(:denied)
        end
      end
    end
  end
end
