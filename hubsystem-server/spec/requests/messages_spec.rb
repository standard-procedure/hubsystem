require "rails_helper"

RSpec.describe "Messages", type: :request do
  let(:sender) { create(:human_participant) }
  let(:recipient) { create(:human_participant) }

  describe "POST /participants/:participant_id/messages" do
    let(:valid_params) do
      {
        message: {
          subject: "Hello there",
          parts: [
            { content_type: "text/plain", body: "Hello!" }
          ]
        }
      }
    end

    context "with valid token" do
      it "creates a message and returns 201" do
        post "/participants/#{recipient.id}/messages",
          params: valid_params,
          headers: { "X-Hub-Token" => sender.token }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["from_id"]).to eq(sender.id)
        expect(json["to_id"]).to eq(recipient.id)
        expect(json["parts"].length).to eq(1)
      end
    end

    context "without token" do
      it "returns 401" do
        post "/participants/#{recipient.id}/messages", params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with invalid token" do
      it "returns 401" do
        post "/participants/#{recipient.id}/messages",
          params: valid_params,
          headers: { "X-Hub-Token" => "bad-token" }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when recipient is an AgentParticipant" do
      let(:agent) { create(:agent_participant) }
      let(:pipeline) { instance_double(AgentPipeline) }

      before do
        allow(AgentPipeline).to receive(:new).and_return(pipeline)
        allow(pipeline).to receive(:process)
      end

      it "calls AgentPipeline.process after creating the message" do
        expect(pipeline).to receive(:process) do |msg|
          expect(msg.to).to eq(agent)
        end

        post "/participants/#{agent.id}/messages",
          params: valid_params,
          headers: { "X-Hub-Token" => sender.token }

        expect(response).to have_http_status(:created)
      end
    end
  end

  describe "GET /participants/:participant_id/messages" do
    before do
      create(:message, from: sender, to: recipient)
    end

    context "with valid token" do
      it "returns inbox messages" do
        get "/participants/#{recipient.id}/messages",
          headers: { "X-Hub-Token" => recipient.token }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.length).to be >= 1
        expect(json.first["to_id"]).to eq(recipient.id)
      end
    end

    context "without token" do
      it "returns 401" do
        get "/participants/#{recipient.id}/messages"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
