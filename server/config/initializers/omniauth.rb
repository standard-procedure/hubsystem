Rails.application.config.middleware.use OmniAuth::Builder do
  provider :developer, fields: [:uid], uid_field: :uid if Rails.env.local?
end

OmniAuth.config.logger = Rails.logger
