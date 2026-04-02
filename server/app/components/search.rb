# frozen_string_literal: true

class Components::Search < Components::Base
  include Phlex::Rails::Helpers::FormWith

  prop :search, String
  prop :url, String
  prop :placeholder, _String?

  def view_template
    form_with url: @url, method: :get do |form|
      Row justify: "between", wrap: false, gap: 2 do
        form.search_field :search, value: @search, placeholder: placeholder_text, class: %w[input-field grow-1]
        Button label: t(".search"), variant: :secondary, size: :sm
      end
    end
  end

  private def placeholder_text = @placeholder || t(".placeholder")
end
