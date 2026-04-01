# frozen_string_literal: true

class Views::Base < Components::Base
  include Phlex::Rails::Helpers::FormAuthenticityToken
  include Phlex::Rails::Helpers::T
  include Phlex::Rails::Helpers::L

  def cache_store = Rails.cache
end
