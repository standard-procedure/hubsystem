require "rails_helper"

RSpec.describe Amygdala::EmotionUpdater do
  let(:updater) { described_class.new }
  let(:agent) do
    create(:agent_participant, emotion_parameters: {
      "happy" => 75, "anxious" => 10, "focused" => 80, "exhausted" => 0, "irritated" => 10
    })
  end

  def message_with_body(body)
    msg = create(:message, to: agent)
    msg.parts.first.update!(body: body) if msg.parts.any?
    msg.parts.create!(content_type: "text/plain", body: body, position: 0) unless msg.parts.any?
    msg
  end

  describe "#update with direction: :inbound" do
    it "increments exhausted by 2 for a normal message" do
      msg = create(:message, to: agent)
      updater.update(agent, msg, direction: :inbound)
      expect(agent.reload.emotion_parameters["exhausted"]).to eq(2)
    end

    it "increments anxious +5 and decrements happy -3 for hostile keywords" do
      msg = message_with_body("I hate this system")
      updater.update(agent, msg, direction: :inbound)
      params = agent.reload.emotion_parameters
      expect(params["anxious"]).to eq(15)
      expect(params["happy"]).to eq(72)
    end

    it "does not increment happy for inbound" do
      msg = create(:message, to: agent)
      updater.update(agent, msg, direction: :inbound)
      expect(agent.reload.emotion_parameters["happy"]).to eq(75)
    end
  end

  describe "#update with direction: :outbound" do
    it "increments happy by 1" do
      msg = create(:message, from: agent)
      updater.update(agent, msg, direction: :outbound)
      expect(agent.reload.emotion_parameters["happy"]).to eq(76)
    end

    it "does not increment exhausted for outbound" do
      msg = create(:message, from: agent)
      updater.update(agent, msg, direction: :outbound)
      expect(agent.reload.emotion_parameters["exhausted"]).to eq(0)
    end
  end

  describe "#update with direction: :do_not_process" do
    it "increments anxious by 10" do
      msg = create(:message, to: agent)
      updater.update(agent, msg, direction: :do_not_process)
      expect(agent.reload.emotion_parameters["anxious"]).to eq(20)
    end

    it "increments irritated by 5" do
      msg = create(:message, to: agent)
      updater.update(agent, msg, direction: :do_not_process)
      expect(agent.reload.emotion_parameters["irritated"]).to eq(15)
    end
  end

  describe "clamping" do
    it "clamps values to 0 minimum" do
      agent.update!(emotion_parameters: agent.emotion_parameters.merge("happy" => 1))
      msg = message_with_body("I will kill and destroy and attack you with hate")
      updater.update(agent, msg, direction: :inbound)
      expect(agent.reload.emotion_parameters["happy"]).to eq(0)
    end

    it "clamps values to 100 maximum" do
      agent.update!(emotion_parameters: agent.emotion_parameters.merge("anxious" => 98))
      msg = create(:message, to: agent)
      updater.update(agent, msg, direction: :do_not_process)
      expect(agent.reload.emotion_parameters["anxious"]).to eq(100)
    end
  end
end
