require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module TestApp
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    config.root = File.expand_path("..", __dir__)
    config.eager_load = false
  end
end
