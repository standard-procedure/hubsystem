require "rails_helper"

RSpec.describe Amygdala::ThreatEvaluator do
  let(:agent) { create(:agent_participant) }
  let(:sender) { create(:human_participant) }
  let(:message) { create(:message, from: sender, to: agent) }
  let(:llm_provider) { double("LlmProvider") }
  let(:evaluator) { described_class.new(llm_provider: llm_provider) }

  describe "#evaluate" do
    context "when sender has a SecurityPass with 'trusted' capability" do
      before do
        group = create(:group)
        create(:security_pass, participant: sender, group: group, capabilities: ["trusted"])
      end

      it "returns :safe without calling the LLM" do
        expect(llm_provider).not_to receive(:evaluate_threat)
        expect(evaluator.evaluate(message, agent)).to eq(:safe)
      end
    end

    context "when sender does not have a trusted SecurityPass" do
      it "calls the LLM provider and returns its result" do
        allow(llm_provider).to receive(:evaluate_threat).and_return(:safe)
        expect(evaluator.evaluate(message, agent)).to eq(:safe)
      end

      it "returns :dodgy when the LLM returns :dodgy" do
        allow(llm_provider).to receive(:evaluate_threat).and_return(:dodgy)
        expect(evaluator.evaluate(message, agent)).to eq(:dodgy)
      end

      it "returns :do_not_process when the LLM returns :do_not_process" do
        allow(llm_provider).to receive(:evaluate_threat).and_return(:do_not_process)
        expect(evaluator.evaluate(message, agent)).to eq(:do_not_process)
      end

      it "increments sender suspicion_count when result is :do_not_process" do
        allow(llm_provider).to receive(:evaluate_threat).and_return(:do_not_process)
        expect {
          evaluator.evaluate(message, agent)
        }.to change { sender.reload.suspicion_count }.by(1)
      end

      it "does not increment suspicion_count for :dodgy result" do
        allow(llm_provider).to receive(:evaluate_threat).and_return(:dodgy)
        expect {
          evaluator.evaluate(message, agent)
        }.not_to change { sender.reload.suspicion_count }
      end
    end
  end
end
