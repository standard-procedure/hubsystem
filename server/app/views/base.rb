# frozen_string_literal: true

class Views::Base < Components::Base
  include Phlex::Rails::Helpers::FormAuthenticityToken

  def cache_store = Rails.cache
end
