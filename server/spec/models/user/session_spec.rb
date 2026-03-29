# frozen_string_literal: true

require "rails_helper"

RSpec.describe User::Session, type: :model do
  fixtures :users, :humans, :synthetics, :synthetic_classes, :user_sessions

  describe "associations" do
    it "belongs to a user" do
      session = user_sessions(:alice_session)
      expect(session.user).to eq(users(:alice))
    end
  end
end
