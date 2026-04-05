# frozen_string_literal: true

require "rails_helper"

RSpec.describe HubSystem::CommandLogEntry, type: :model do
  let(:user) { User.create!(name: "Alice") }

  it "stores command execution details" do
    entry = described_class.create!(
      command_class: "Widget::Frobnicate",
      actor: user,
      params: {widget_id: 1, name: "test"},
      status: :started
    )
    expect(entry).to be_started
    expect(entry.command_class).to eq("Widget::Frobnicate")
    expect(entry.actor).to eq(user)
    expect(entry.params).to eq({"widget_id" => 1, "name" => "test"})
  end

  it "transitions to completed" do
    entry = described_class.create!(command_class: "Widget::Frobnicate", actor: user, status: :started)
    entry.update!(status: :completed, result: "Widget#1")
    expect(entry).to be_completed
    expect(entry.result).to eq("Widget#1")
  end

  it "transitions to failed" do
    entry = described_class.create!(command_class: "Widget::Frobnicate", actor: user, status: :started)
    entry.update!(status: :failed, error: "RuntimeError: something broke")
    expect(entry).to be_failed
    expect(entry.error).to eq("RuntimeError: something broke")
  end
end
