RSpec.describe "Participants API" do
  let(:client) { ApiClient.new(token: ServerManager.baz_token) }

  describe "GET /participants" do
    it "returns 200 with a list that includes Baz and Aria" do
      response = client.get("/participants")

      expect(response.status).to eq(200)

      names = response.body.map { |p| p["name"] }
      expect(names).to include("Baz")
      expect(names).to include("Aria")
    end

    it "returns 401 without a token" do
      unauthed = ApiClient.new
      response = unauthed.get("/participants")
      expect(response.status).to eq(401)
    end
  end
end
