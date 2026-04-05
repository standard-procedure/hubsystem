# frozen_string_literal: true

require "rails_helper"

RSpec.describe HubSystem::SecurityPass, type: :model do
  let(:user) { User.create!(name: "Alice") }
  let(:widget) { Widget.create!(name: "Test Widget") }

  # Use BasicSecurityPass for testing since SecurityPass is abstract
  let(:pass) do
    HubSystem::BasicSecurityPass.create!(
      resource: widget,
      user: user,
      data: {commands: '["read", "write"]', from_date: 1.day.ago.to_date.to_s, until_date: 1.day.from_now.to_date.to_s}
    )
  end

  let(:open_pass) do
    HubSystem::BasicSecurityPass.create!(
      resource: widget,
      user: user,
      data: {commands: "[]", from_date: 1.day.ago.to_date.to_s, until_date: 1.day.from_now.to_date.to_s}
    )
  end

  describe "associations" do
    it "belongs to a resource (polymorphic)" do
      expect(pass.resource).to eq(widget)
    end

    it "belongs to a user (polymorphic)" do
      expect(pass.user).to eq(user)
    end
  end

  describe "status" do
    it "defaults to locked" do
      expect(pass).to be_locked
    end
  end

  describe "#allows?" do
    it "allows any request when commands is empty" do
      expect(open_pass.allows?("anything")).to be true
    end

    it "allows requests that are in the commands list" do
      expect(pass.allows?("read")).to be true
      expect(pass.allows?("write")).to be true
    end

    it "denies requests not in the commands list" do
      expect(pass.allows?("delete")).to be false
    end

    it "allows multiple requests when all are in the list" do
      expect(pass.allows?("read", "write")).to be true
    end

    it "denies when any request is not in the list" do
      expect(pass.allows?("read", "delete")).to be false
    end
  end

  describe "#authorise!" do
    it "raises Unauthorised when authorised? returns false" do
      expired_pass = HubSystem::BasicSecurityPass.create!(
        resource: widget,
        user: user,
        data: {commands: "[]", from_date: 2.days.ago.to_date.to_s, until_date: 1.day.ago.to_date.to_s}
      )
      expect { expired_pass.authorise!("read") }.to raise_error(HubSystem::SecurityPass::Unauthorised)
    end

    it "does not raise when authorised? returns true" do
      expect { pass.authorise!("read") }.not_to raise_error
    end
  end

  describe "#unlock" do
    it "yields the resource when authorised" do
      yielded = nil
      pass.unlock("read") { |resource| yielded = resource }
      expect(yielded).to eq(widget)
    end

    it "sets status to unlocked during the block" do
      status_during = nil
      pass.unlock("read") { status_during = pass.status }
      expect(status_during).to eq("unlocked")
    end

    it "re-locks after the block completes" do
      pass.unlock("read") { }
      expect(pass.reload).to be_locked
    end

    it "re-locks even if the block raises" do
      pass.unlock("read") { raise "Boom!" } rescue nil
      expect(pass.reload).to be_locked
    end

    it "raises Unauthorised without yielding if auth fails" do
      expired_pass = HubSystem::BasicSecurityPass.create!(
        resource: widget,
        user: user,
        data: {commands: "[]", from_date: 2.days.ago.to_date.to_s, until_date: 1.day.ago.to_date.to_s}
      )
      yielded = false
      expect {
        expired_pass.unlock("read") { yielded = true }
      }.to raise_error(HubSystem::SecurityPass::Unauthorised)
      expect(yielded).to be false
    end
  end
end
