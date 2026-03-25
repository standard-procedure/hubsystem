# frozen_string_literal: true

require "rails_helper"

RSpec.describe User::Synthetic, type: :model do
  fixtures :users

  it "is a User subclass" do
    expect(User::Synthetic.superclass).to eq(User)
  end

  it "loads synthetic users from fixtures" do
    bishop = users(:bishop)
    expect(bishop).to be_a(User::Synthetic)
  end
end
