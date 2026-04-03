require "rails_helper"

OmniAuth.config.test_mode = true

test_interface = ActiveSupport::StringInquirer.new(ENV.fetch("TEST_INTERFACE", "web"))

if test_interface.web?
  require "turnip/capybara"
  require "capybara/playwright"

  Capybara.register_driver :chromium do |app|
    Capybara::Playwright::Driver.new(app, browser_type: :chromium, headless: true, viewport: {width: 1600, height: 1600})
  end

  Capybara.javascript_driver = :chromium
  Capybara.configure do |config|
    config.server = :puma
    config.server_host = "localhost"
    config.server_port = 3001 + ENV["TEST_ENV_NUMBER"].to_i
  end
  Capybara.default_max_wait_time = 30
  Capybara.save_path = "tmp/capybara#{ENV["TEST_ENV_NUMBER"]}"
elsif test_interface.api?
  require_relative "support/api_client"
end

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join("spec/fixtures")]
  config.global_fixtures = :all

  config.before :all do
    Dir["spec/features/steps/*_steps.rb"].each do |step_file|
      require File.expand_path(step_file)
      module_name = step_file.gsub("spec/features/steps/", "").gsub(".rb", "").camelize
      config.include module_name.constantize
    end

    if test_interface.web?
      config.include ActionView::RecordIdentifier
      Capybara.app_host = "http://#{Capybara.server_host}:#{Capybara.server_port}"

      Dir["spec/features/steps/web/*_steps.rb"].each do |step_file|
        require File.expand_path(step_file)
      end

    elsif test_interface.api?
      config.include ApiClient
      config.include Rails.application.routes.url_helpers

      Dir["spec/features/steps/api/*_steps.rb"].each do |step_file|
        require File.expand_path(step_file)
      end
    end
  end

  config.after :each do
    OmniAuth.config.mock_auth[:developer] = nil
  end

  config.around background_jobs: true do |example|
    ActiveJob::Base.queue_adapter = :inline
    example.run
    ActiveJob::Base.queue_adapter = :test
  end
end
