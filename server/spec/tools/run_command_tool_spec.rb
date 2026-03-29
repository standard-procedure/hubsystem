# frozen_string_literal: true

require "rails_helper"
require "open3"

RSpec.describe RunCommandTool, type: :model do
  fixtures :users, :humans, :synthetics

  let(:bishop) { users(:bishop) }
  let(:tool) { described_class.new(bishop) }

  describe "#execute" do
    it "executes a command and returns output" do
      allow(tool).to receive(:system)
      allow(Open3).to receive(:capture3).and_return(["hello world\n", "", instance_double(Process::Status, success?: true, exitstatus: 0)])

      result = tool.execute(command: "echo hello world")
      expect(result).to include("hello world")
    end

    it "includes stderr in output" do
      allow(tool).to receive(:system)
      allow(Open3).to receive(:capture3).and_return(["", "warning: something\n", instance_double(Process::Status, success?: true, exitstatus: 0)])

      result = tool.execute(command: "some_command")
      expect(result).to include("STDERR")
      expect(result).to include("warning: something")
    end

    it "reports non-zero exit codes" do
      allow(tool).to receive(:system)
      allow(Open3).to receive(:capture3).and_return(["", "not found\n", instance_double(Process::Status, success?: false, exitstatus: 127)])

      result = tool.execute(command: "nonexistent_command")
      expect(result).to include("Exit code: 127")
    end

    it "handles timeouts" do
      allow(tool).to receive(:system)
      allow(Open3).to receive(:capture3).and_raise(Timeout::Error)

      result = tool.execute(command: "sleep 999", timeout: 5)
      expect(result).to include("timed out")
    end

    it "caps timeout at 120 seconds" do
      allow(tool).to receive(:system)
      expect(Open3).to receive(:capture3).with(
        "docker", "exec", "-w", "/workspaces/sandbox/bishop", "sandbox",
        "bash", "-c", "echo test",
        timeout: 120
      ).and_return(["ok\n", "", instance_double(Process::Status, success?: true, exitstatus: 0)])

      tool.execute(command: "echo test", timeout: 999)
    end
  end
end
