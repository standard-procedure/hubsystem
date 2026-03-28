# frozen_string_literal: true

module ApiClient
  def auth_header(token) = {"Authorization" => "Bearer #{token.respond_to?(:token) ? token.token : token}"}

  def app
    Rails.application
  end

  def get(path, **options)
    @last_response = Rack::Test::Session.new(app).get(path, options[:params] || {}, rack_headers(options[:headers]))
  end

  def post(path, **options)
    @last_response = Rack::Test::Session.new(app).post(path, (options[:params] || {}).to_json, rack_headers(options[:headers]).merge("CONTENT_TYPE" => "application/json"))
  end

  def patch(path, **options)
    @last_response = Rack::Test::Session.new(app).patch(path, (options[:params] || {}).to_json, rack_headers(options[:headers]).merge("CONTENT_TYPE" => "application/json"))
  end

  def response
    @last_response
  end

  private

  def rack_headers(headers)
    return {} unless headers
    headers.transform_keys { |k| "HTTP_#{k.upcase.tr("-", "_")}" }
  end
end
