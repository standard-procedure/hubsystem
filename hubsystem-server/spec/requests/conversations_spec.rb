require "rails_helper"

RSpec.describe "Conversations", type: :request do
  let(:sender) { create(:human_participant) }
  let(:recipient) { create(:human_participant) }

  describe "POST /conversations" do
    let(:valid_params) do
      {
        conversation: {
          subject: "Let's talk",
          message: {
            subject: "First message",
            to_id: recipient.id,
            parts: [
              { content_type: "text/plain", body: "Hello!" }
            ]
          }
        }
      }
    end

    context "with valid token" do
      it "creates a conversation and returns 201" do
        post "/conversations",
          params: valid_params,
          headers: { "X-Hub-Token" => sender.token }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["subject"]).to eq("Let's talk")
      end
    end

    context "without token" do
      it "returns 401" do
        post "/conversations", params: valid_params
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with participant_slugs format (CLI format)" do
      let(:agent) { create(:agent_participant, slug: "aria") }

      let(:slug_params) do
        {
          conversation: {
            subject: "Hello from CLI",
            participant_slugs: [agent.slug],
            initial_message: "Hi there from CLI"
          }
        }
      end

      it "creates a conversation with the named participants and returns 201" do
        post "/conversations",
          params: slug_params,
          headers: { "X-Hub-Token" => sender.token }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["subject"]).to eq("Hello from CLI")
        expect(json["id"]).to be_present
      end
    end
  end

  describe "GET /conversations/:id/messages" do
    let(:conversation) { create(:conversation) }

    before do
      create(:conversation_membership, conversation: conversation, participant: sender)
      create(:conversation_membership, conversation: conversation, participant: recipient)
      msg = create(:message, from: sender, to: recipient, conversation: conversation)
    end

    context "as a member with valid token" do
      it "returns messages" do
        get "/conversations/#{conversation.id}/messages",
          headers: { "X-Hub-Token" => sender.token }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.length).to be >= 1
      end
    end

    context "as a non-member" do
      let(:outsider) { create(:human_participant) }

      it "returns 401" do
        get "/conversations/#{conversation.id}/messages",
          headers: { "X-Hub-Token" => outsider.token }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "without token" do
      it "returns 401" do
        get "/conversations/#{conversation.id}/messages"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
