# frozen_string_literal: true

module AuthenticationHelper
  def sign_in_as(user_session)
    jar = ActionDispatch::Request.new(Rails.application.env_config.dup).cookie_jar
    jar.signed[:session_id] = {value: user_session.id, httponly: true}
    cookies[:session_id] = jar[:session_id]
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :request
  config.include AuthenticationHelper, type: :feature
end
