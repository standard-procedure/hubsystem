# frozen_string_literal: true

require "rails_helper"

RSpec.describe HasStatusBadge do
  # Tested through Conversation which includes it. The concern only adds a
  # single enum definition — specs verify values, defaults, and predicates.
  fixtures :conversations

  it "defines the expected enum values" do
    expect(Conversation.status_badges).to eq(
      "offline" => 0, "online" => 10, "alert" => 20, "warning" => 30, "critical" => 50
    )
  end

  it "defaults to offline" do
    expect(Conversation.new.status_badge).to eq("offline")
  end

  it "provides predicate methods for each value" do
    conversation = conversations(:alpha) # online

    expect(conversation).to be_online
    expect(conversation).not_to be_offline
    expect(conversation).not_to be_alert
    expect(conversation).not_to be_warning
    expect(conversation).not_to be_critical
  end

  it "can be updated to any valid value" do
    conversation = conversations(:beta)
    %i[online alert warning critical offline].each do |badge|
      conversation.update!(status_badge: badge)
      expect(conversation.status_badge).to eq(badge.to_s)
    end
  end
end
