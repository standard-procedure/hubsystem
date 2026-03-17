require "rails_helper"

RSpec.describe "Messages inbox", type: :request do
  let(:me)     { create(:human_participant) }
  let(:sender) { create(:human_participant) }

  before do
    msg = create(:message, from: sender, to: me, subject: "Hello")
    msg.parts.destroy_all
    create(:message_part, message: msg, content_type: "text/plain", body: "Hey there", position: 0)
  end

  describe "GET /messages/inbox" do
    context "with valid token" do
      it "returns messages addressed to the current participant" do
        get "/messages/inbox", headers: { "X-Hub-Token" => me.token }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
        expect(json.first["subject"]).to eq("Hello")
        expect(json.first["from"]["name"]).to eq(sender.name)
        expect(json.first["parts"].first["body"]).to eq("Hey there")
      end

      it "does not return messages sent to other participants" do
        other = create(:human_participant)
        create(:message, from: sender, to: other)

        get "/messages/inbox", headers: { "X-Hub-Token" => me.token }

        json = JSON.parse(response.body)
        expect(json.length).to eq(1)
      end
    end

    context "without token" do
      it "returns 401" do
        get "/messages/inbox"
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
