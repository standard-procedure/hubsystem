require "faraday"

class ApiClient
  BASE_URL = ServerManager::SERVER_URL

  def initialize(token: nil)
    @token = token
    @conn = Faraday.new(url: BASE_URL) do |f|
      f.request :json
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  def get(path)
    @conn.get(path) { |req| req.headers["X-Hub-Token"] = @token if @token }
  end

  def post(path, body = {})
    @conn.post(path, body) { |req| req.headers["X-Hub-Token"] = @token if @token }
  end
end
