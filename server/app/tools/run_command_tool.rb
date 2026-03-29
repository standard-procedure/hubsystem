# frozen_string_literal: true

class RunCommandTool < SyntheticTool
  description "Execute a bash command in your sandboxed workspace. You can install packages, run scripts, and manage files."

  param :command, type: "string", desc: "The bash command to execute", required: true
  param :timeout, type: "integer", desc: "Timeout in seconds (default 30, max 120)", required: false

  SANDBOX_CONTAINER = ENV.fetch("SANDBOX_CONTAINER", "sandbox")

  def execute(command:, timeout: 30)
    timeout = [timeout.to_i, 120].min
    workspace = "/workspaces/sandbox/#{@synthetic.uid}"

    # Ensure workspace directory exists
    system("docker", "exec", SANDBOX_CONTAINER, "mkdir", "-p", workspace)

    # Execute the command with timeout
    stdout, stderr, status = Open3.capture3(
      "docker", "exec",
      "-w", workspace,
      SANDBOX_CONTAINER,
      "bash", "-c", command,
      timeout: timeout
    )

    output = stdout.presence || ""
    output += "\nSTDERR: #{stderr}" if stderr.present?
    output += "\nExit code: #{status.exitstatus}" unless status.success?
    output.presence || "Command completed successfully."
  rescue Timeout::Error
    "Command timed out after #{timeout} seconds."
  rescue => e
    "Error executing command: #{e.message}"
  end
end
