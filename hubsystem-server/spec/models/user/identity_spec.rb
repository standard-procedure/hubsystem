# frozen_string_literal: true

require "rails_helper"

RSpec.describe User::Identity, type: :model do
  fixtures :users, :user_identities

  describe "validations" do
    it "requires a provider" do
      identity = User::Identity.new(user: users(:alice), provider: nil, uid: "123")
      expect(identity).not_to be_valid
      expect(identity.errors[:provider]).to include("can't be blank")
    end

    it "requires a uid" do
      identity = User::Identity.new(user: users(:alice), provider: "github", uid: nil)
      expect(identity).not_to be_valid
      expect(identity.errors[:uid]).to include("can't be blank")
    end
  end

  describe "associations" do
    it "belongs to a user" do
      identity = user_identities(:alice_google)
      expect(identity.user).to eq(users(:alice))
    end
  end

  describe ".authenticate" do
    it "returns the identity matching provider and uid" do
      omniauth = {"provider" => "google", "uid" => "alice-google-123"}
      identity = User::Identity.authenticate(omniauth)
      expect(identity).to eq(user_identities(:alice_google))
    end

    it "raises ActiveRecord::RecordNotFound for unknown credentials" do
      omniauth = {"provider" => "google", "uid" => "unknown"}
      expect { User::Identity.authenticate(omniauth) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
