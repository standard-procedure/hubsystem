RSpec.describe "Conversations API" do
  let(:baz_client) { ApiClient.new(token: ServerManager.baz_token) }
  let(:unauthed)   { ApiClient.new }

  def aria_id
    participants = baz_client.get("/participants").body
    participants.find { |p| p["slug"] == "aria" }["id"]
  end

  describe "POST /conversations" do
    it "returns 201 and creates a conversation with baz and aria as members" do
      response = baz_client.post("/conversations", {
        conversation: {
          subject: "Let's talk",
          message: {
            to_id: aria_id,
            subject: "Opening message",
            parts: [{ content_type: "text/plain", body: "Hey Aria, got a moment?" }]
          }
        }
      })

      expect(response.status).to eq(201)
      expect(response.body["id"]).to be_a(Integer)
      expect(response.body["subject"]).to eq("Let's talk")
    end

    it "returns 401 without a token" do
      response = unauthed.post("/conversations", {
        conversation: {
          subject: "Sneaky",
          message: { to_id: aria_id, parts: [{ content_type: "text/plain", body: "Hello" }] }
        }
      })
      expect(response.status).to eq(401)
    end
  end

  describe "GET /conversations/:id/messages" do
    let(:conversation_id) do
      res = baz_client.post("/conversations", {
        conversation: {
          subject: "Test convo",
          message: {
            to_id: aria_id,
            subject: "Opener",
            parts: [{ content_type: "text/plain", body: "Starting a conversation" }]
          }
        }
      })
      res.body["id"]
    end

    it "returns 200 with messages for a conversation member" do
      id = conversation_id
      response = baz_client.get("/conversations/#{id}/messages")

      expect(response.status).to eq(200)
      expect(response.body).to be_an(Array)
      expect(response.body.length).to be >= 1
    end

    it "returns 401 for a non-member without a token" do
      id = conversation_id
      response = unauthed.get("/conversations/#{id}/messages")
      expect(response.status).to eq(401)
    end
  end
end
