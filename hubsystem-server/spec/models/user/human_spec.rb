# frozen_string_literal: true

require "rails_helper"

RSpec.describe User::Human, type: :model do
  fixtures :users, :user_identities

  it "is a User subclass" do
    expect(User::Human.superclass).to eq(User)
  end

  it "loads human users from fixtures" do
    alice = users(:alice)
    expect(alice).to be_a(User::Human)
  end

  describe "associations" do
    it "has many identities" do
      alice = users(:alice)
      expect(alice.identities).to include(user_identities(:alice_google))
    end

    it "destroys dependent identities" do
      alice = users(:alice)
      expect { alice.destroy }.to change(User::Identity, :count).by(-1)
    end
  end
end
