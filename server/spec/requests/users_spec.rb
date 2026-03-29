# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Users", type: :request do
  fixtures :users, :humans, :synthetics, :synthetic_classes, :user_sessions

  before { sign_in_as user_sessions(:alice_session) }

  describe "GET /users" do
    it "lists active users" do
      get users_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Alice Aardvark")
      expect(response.body).to include("Bishop")
    end

    it "searches users by name" do
      get users_path(q: "Bishop")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Bishop")
      expect(response.body).not_to include("Alice Aardvark")
    end

    it "shows empty state for no results" do
      get users_path(q: "zzzznotfound")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No users found")
    end
  end

  describe "GET /users/:id" do
    it "shows user details" do
      get user_path(users(:bishop))
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Bishop")
      expect(response.body).to include("Synthetic")
    end

    it "shows synthetic profile for synthetic users" do
      get user_path(users(:bishop))
      expect(response.body).to include("Calm and methodical")
      expect(response.body).to include("Standard Agent")
    end

    it "shows notes visible to the current user" do
      Note.create!(subject: users(:bishop), author: users(:alice), content: "My private observation")
      get user_path(users(:bishop))
      expect(response.body).to include("My private observation")
    end

    it "does not show other users' private notes" do
      Note.create!(subject: users(:bishop), author: users(:bob), content: "Bob's secret", visibility: "private")
      get user_path(users(:bishop))
      expect(response.body).not_to include("Bob's secret")
    end
  end
end
