RSpec.describe "Messages API" do
  let(:baz_client)    { ApiClient.new(token: ServerManager.baz_token) }
  let(:unauthed)      { ApiClient.new }

  let(:aria_slug) { "aria" }
  let(:baz_slug)  { "baz" }

  def aria_id
    participants = baz_client.get("/participants").body
    participants.find { |p| p["slug"] == aria_slug }["id"]
  end

  def baz_id
    participants = baz_client.get("/participants").body
    participants.find { |p| p["slug"] == baz_slug }["id"]
  end

  describe "POST /participants/:id/messages" do
    it "returns 201 and creates a message with a valid token" do
      response = baz_client.post("/participants/#{aria_id}/messages", {
        message: {
          subject: "Hello Aria",
          parts: [
            { content_type: "text/plain", body: "How are you today?" }
          ]
        }
      })

      expect(response.status).to eq(201)
      expect(response.body["subject"]).to eq("Hello Aria")
      expect(response.body["parts"].length).to eq(1)
    end

    it "returns 401 without a token" do
      response = unauthed.post("/participants/#{aria_id}/messages", {
        message: {
          subject: "Sneaky message",
          parts: [{ content_type: "text/plain", body: "Can you hear me?" }]
        }
      })

      expect(response.status).to eq(401)
    end
  end

  describe "GET /participants/:id/messages" do
    before do
      # Send a message to baz so there's something in the inbox
      baz_client.post("/participants/#{baz_id}/messages", {
        message: {
          subject: "Message for Baz",
          parts: [{ content_type: "text/plain", body: "Hello Baz" }]
        }
      })
    end

    it "returns 200 with messages for a valid token" do
      response = baz_client.get("/participants/#{baz_id}/messages")

      expect(response.status).to eq(200)
      expect(response.body).to be_an(Array)
      expect(response.body.length).to be >= 1
    end

    it "returns 401 without a token" do
      response = unauthed.get("/participants/#{baz_id}/messages")
      expect(response.status).to eq(401)
    end
  end
end
