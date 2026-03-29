# frozen_string_literal: true

require "rails_helper"

RSpec.describe Human, type: :model do
  fixtures :users, :humans, :user_identities

  it "has a user via delegated type" do
    alice = users(:alice)
    expect(alice).to be_human
    expect(alice.role).to be_a(Human)
  end

  describe "associations" do
    it "has many identities" do
      alice_human = humans(:alice_human)
      expect(alice_human.identities).to include(user_identities(:alice_developer))
    end

    it "destroys dependent identities" do
      alice = users(:alice)
      expect { alice.destroy }.to change(User::Identity, :count).by(-1)
    end
  end
end
