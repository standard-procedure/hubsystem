# The integration environment is used by the external integration test suite
# (hubsystem-integration/). It runs the full Rails server against a dedicated
# database so integration specs can reset it without touching the unit test DB.

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Use a fixed key for integration tests — not secret, just needs to be set.
  config.secret_key_base = ENV.fetch("SECRET_KEY_BASE", "hubsystem_integration_test_secret_key_base_not_for_production_use")

  # While tests run files are not watched, reloading is not necessary.
  config.enable_reloading = false

  # Eager loading loads your entire application. When running a single test locally,
  # this is usually not necessary, and can slow down your test suite. However, it's
  # recommended that you enable it in continuous integration systems to ensure eager
  # loading is working properly before deploying your code.
  config.eager_load = ENV["CI"].present?

  # Configure public file server for tests with cache-control for performance.
  config.public_file_server.headers = { "cache-control" => "public, max-age=3600" }

  # Show full error reports.
  config.consider_all_requests_local = true
  config.cache_store = :null_store

  # Render exception templates for rescuable exceptions and raise for other exceptions.
  config.action_dispatch.show_exceptions = :rescuable

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raise error when a before_action's only/except options reference missing actions.
  config.action_controller.raise_on_missing_callback_actions = true
end
