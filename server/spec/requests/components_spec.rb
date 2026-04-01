# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Components", type: :request do
  fixtures :users, :user_sessions

  describe "GET /component" do
    it "returns the component gallery" do
      sign_in_as user_sessions(:alice_session)
      get component_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Component Gallery")
    end
  end
end
