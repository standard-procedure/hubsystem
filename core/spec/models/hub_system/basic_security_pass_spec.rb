# frozen_string_literal: true

require "rails_helper"

RSpec.describe HubSystem::BasicSecurityPass, type: :model do
  let(:user) { User.create!(name: "Alice") }
  let(:widget) { Widget.create!(name: "Test Widget") }

  def create_pass(from_date: 1.day.ago.to_date, until_date: 1.day.from_now.to_date, commands: [])
    described_class.create!(
      resource: widget,
      user: user,
      data: {
        from_date: from_date&.to_s,
        until_date: until_date&.to_s,
        commands: commands.to_json
      }
    )
  end

  describe "#authorised?" do
    context "date range" do
      it "returns true when today is within the date range" do
        pass = create_pass(from_date: 1.day.ago.to_date, until_date: 1.day.from_now.to_date)
        expect(pass.authorised?).to be true
      end

      it "returns false when today is before the from_date" do
        pass = create_pass(from_date: 1.day.from_now.to_date, until_date: 2.days.from_now.to_date)
        expect(pass.authorised?).to be false
      end

      it "returns false when today is after the until_date" do
        pass = create_pass(from_date: 2.days.ago.to_date, until_date: 1.day.ago.to_date)
        expect(pass.authorised?).to be false
      end

      it "returns true when no dates are set" do
        pass = create_pass(from_date: nil, until_date: nil)
        expect(pass.authorised?).to be true
      end

      it "returns true when only from_date is set and today is after it" do
        pass = create_pass(from_date: 1.day.ago.to_date, until_date: nil)
        expect(pass.authorised?).to be true
      end

      it "returns false when only from_date is set and today is before it" do
        pass = create_pass(from_date: 1.day.from_now.to_date, until_date: nil)
        expect(pass.authorised?).to be false
      end
    end

    context "commands" do
      it "returns true when commands match" do
        pass = create_pass(commands: ["read", "write"])
        expect(pass.authorised?("read")).to be true
      end

      it "returns false when commands don't match" do
        pass = create_pass(commands: ["read", "write"])
        expect(pass.authorised?("delete")).to be false
      end

      it "returns true with empty commands (allows everything)" do
        pass = create_pass(commands: [])
        expect(pass.authorised?("anything")).to be true
      end
    end

    context "date AND commands" do
      it "returns false when date is valid but commands don't match" do
        pass = create_pass(commands: ["read"])
        expect(pass.authorised?("delete")).to be false
      end

      it "returns false when commands match but date is invalid" do
        pass = create_pass(from_date: 2.days.ago.to_date, until_date: 1.day.ago.to_date, commands: ["read"])
        expect(pass.authorised?("read")).to be false
      end
    end
  end

  describe "HasAttributes integration" do
    it "persists from_date and until_date via data JSON" do
      pass = create_pass(from_date: Date.new(2026, 1, 1), until_date: Date.new(2026, 12, 31))
      reloaded = described_class.find(pass.id)
      expect(reloaded.from_date).to eq(Date.new(2026, 1, 1))
      expect(reloaded.until_date).to eq(Date.new(2026, 12, 31))
    end

    it "persists commands via data JSON" do
      pass = create_pass(commands: ["read", "write"])
      reloaded = described_class.find(pass.id)
      expect(JSON.parse(reloaded.commands)).to eq(["read", "write"])
    end
  end
end
