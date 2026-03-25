module ApiClient
  def auth_header(token) = {"Authorization" => "Bearer #{token}"}
end
