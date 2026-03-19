# frozen_string_literal: true

require "rails_helper"

RSpec.describe User::Human, type: :model do
  fixtures :users

  it "is a User subclass" do
    expect(User::Human.superclass).to eq(User)
  end

  it "loads human users from fixtures" do
    alice = users(:alice)
    expect(alice).to be_a(User::Human)
  end
end
