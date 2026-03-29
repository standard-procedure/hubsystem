# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  fixtures :users, :humans, :user_sessions

  describe "validations" do
    it "requires a name" do
      user = User.new(name: nil, role: Human.new)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it "requires a unique uid" do
      existing = users(:alice)
      user = User.new(name: "Someone", uid: existing.uid, role: Human.new)
      expect(user).not_to be_valid
      expect(user.errors[:uid]).to include("has already been taken")
    end
  end

  describe "normalizations" do
    it "strips whitespace from name" do
      user = User.new(name: "  Padded Name  ", role: Human.new)
      expect(user.name).to eq("Padded Name")
    end

    it "strips and downcases uid" do
      user = User.new(name: "Test", uid: "  ABC-123  ", role: Human.new)
      expect(user.uid).to eq("abc-123")
    end
  end

  describe "#generate_uid" do
    it "generates a uid from name when blank" do
      user = User.create!(name: "New User", role: Human.create!)
      expect(user.uid).to match(/\Anew-user-\d+\z/)
    end

    it "does not overwrite an existing uid" do
      user = User.create!(name: "New User", uid: "custom-uid", role: Human.create!)
      expect(user.uid).to eq("custom-uid")
    end
  end

  describe "associations" do
    it "has many sessions" do
      alice = users(:alice)
      expect(alice.sessions).to include(user_sessions(:alice_session))
    end

    it "destroys dependent sessions" do
      alice = users(:alice)
      expect { alice.destroy }.to change(User::Session, :count).by(-1)
    end
  end

  describe "delegated type" do
    it "identifies humans" do
      expect(users(:alice)).to be_human
      expect(users(:alice)).not_to be_synthetic
    end

    it "identifies synthetics" do
      expect(users(:bishop)).to be_synthetic
      expect(users(:bishop)).not_to be_human
    end
  end
end
