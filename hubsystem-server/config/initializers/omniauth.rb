Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer if Rails.env.local?
end

OmniAuth.config.logger = Rails.logger
