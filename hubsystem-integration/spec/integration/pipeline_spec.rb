RSpec.describe "Pipeline smoke test" do
  let(:baz_client) { ApiClient.new(token: ServerManager.baz_token) }

  def aria_id
    participants = baz_client.get("/participants").body
    participants.find { |p| p["slug"] == "aria" }["id"]
  end

  def baz_id
    participants = baz_client.get("/participants").body
    participants.find { |p| p["slug"] == "baz" }["id"]
  end

  # Send a message to Aria and return her ID (triggering the pipeline)
  def trigger_pipeline
    id = aria_id
    baz_client.post("/participants/#{id}/messages", {
      message: {
        subject: "Pipeline trigger",
        parts: [{ content_type: "text/plain", body: "Hello Aria, please respond." }]
      }
    })
    id
  end

  describe "message to agent" do
    it "results in a reply appearing in baz's inbox" do
      trigger_pipeline

      response = baz_client.get("/participants/#{baz_id}/messages")
      expect(response.status).to eq(200)

      # At least one message in baz's inbox is from aria
      messages = response.body
      from_ids = messages.map { |m| m["from_id"] }
      expect(from_ids).to include(aria_id)
    end

    it "updates aria's emotion_parameters (exhausted increases after a turn)" do
      id = trigger_pipeline

      response = baz_client.get("/participants/#{id}")
      expect(response.status).to eq(200)

      emotion = response.body["emotion_parameters"]
      # Default exhausted is 0; inbound emotion update adds 2
      expect(emotion["exhausted"]).to be > 0
    end

    it "writes at least one memory record for aria after the turn" do
      id = trigger_pipeline

      response = baz_client.get("/participants/#{id}")
      expect(response.status).to eq(200)

      expect(response.body["memory_count"]).to be >= 1
    end
  end
end
