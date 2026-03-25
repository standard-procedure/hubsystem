# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  fixtures :users, :user_sessions

  describe "validations" do
    it "requires a name" do
      user = User::Human.new(name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:name]).to include("can't be blank")
    end

    it "requires a unique uid" do
      existing = users(:alice)
      user = User::Human.new(name: "Someone", uid: existing.uid)
      expect(user).not_to be_valid
      expect(user.errors[:uid]).to include("has already been taken")
    end
  end

  describe "normalizations" do
    it "strips whitespace from name" do
      user = User::Human.new(name: "  Padded Name  ")
      expect(user.name).to eq("Padded Name")
    end

    it "strips and downcases uid" do
      user = User::Human.new(name: "Test", uid: "  ABC-123  ")
      expect(user.uid).to eq("abc-123")
    end
  end

  describe "#generate_uid" do
    it "generates a uid from name when blank" do
      user = User::Human.create!(name: "New User")
      expect(user.uid).to match(/\Anew-user-\d+\z/)
    end

    it "does not overwrite an existing uid" do
      user = User::Human.create!(name: "New User", uid: "custom-uid")
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
end
