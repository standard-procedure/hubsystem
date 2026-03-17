require_relative "support/server_manager"
require_relative "support/api_client"

RSpec.configure do |config|
  config.before(:suite) { ServerManager.start }
  config.after(:suite)  { ServerManager.stop }

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  # Use expect syntax only
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
