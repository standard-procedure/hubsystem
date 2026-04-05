# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Engine" do
  it "loads the HubSystem module" do
    expect(defined?(HubSystem)).to eq("constant")
  end

  it "loads the HubSystem engine" do
    expect(defined?(HubSystem::Engine)).to eq("constant")
  end
end
