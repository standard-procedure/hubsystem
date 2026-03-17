require "net/http"

module ServerManager
  SERVER_PORT = 3737
  SERVER_URL  = "http://localhost:#{SERVER_PORT}"
  SERVER_ROOT = File.expand_path("../../../hubsystem-server", __dir__)

  SERVER_GEMFILE = File.join(SERVER_ROOT, "Gemfile")

  def self.start
    env = {
      "RAILS_ENV"      => "integration",
      "BUNDLE_GEMFILE" => SERVER_GEMFILE
    }

    # Reset the integration test database (load schema + run seeds)
    system(env, "bundle exec rails db:reset", chdir: SERVER_ROOT)

    # Start server in background
    @pid = spawn(
      env,
      "bundle exec rails server -p #{SERVER_PORT} -b 127.0.0.1",
      chdir: SERVER_ROOT,
      out: "/tmp/hubsystem-integration-server.log",
      err: "/tmp/hubsystem-integration-server.log"
    )

    # Wait for server to be ready
    wait_for_server
  end

  def self.stop
    return unless @pid
    Process.kill("TERM", @pid)
    Process.wait(@pid)
  rescue Errno::ECHILD, Errno::ESRCH
    # Process already gone — fine
  end

  def self.wait_for_server(timeout: 30)
    deadline = Time.now + timeout
    loop do
      begin
        Net::HTTP.get(URI("#{SERVER_URL}/up"))
        return
      rescue
        raise "Server did not start within #{timeout}s. Check /tmp/hubsystem-integration-server.log" if Time.now > deadline
        sleep 0.3
      end
    end
  end

  def self.baz_token
    File.read("/tmp/hubsystem-integration-baz-token").strip
  end
end
