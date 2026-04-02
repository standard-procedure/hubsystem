# frozen_string_literal: true

class Components::Base < Phlex::HTML
  extend Literal::Properties
  include Components::Types
  include ActionView::RecordIdentifier
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::T
  include Phlex::Rails::Helpers::L

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end
end
