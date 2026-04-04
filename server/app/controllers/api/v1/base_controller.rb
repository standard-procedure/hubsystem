# frozen_string_literal: true

class Api::V1::BaseController < ActionController::API
  include ErrorHandlers::Api
  before_action :doorkeeper_authorize!

  private

  def current_user
    @current_user ||= User.find(doorkeeper_token.resource_owner_id)
  end
end
