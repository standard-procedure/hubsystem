# frozen_string_literal: true

class Views::Sessions::New < Views::Base
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::Flash

  def view_template
    render Views::Layouts::Application.new(title: "HubSystem") do
      render_flash
      render Components::Panel.new(title: "Authentication Required", variant: :active, class: %w[grow-1]) do
        Column do
          if Rails.env.local?
            Row justify: "end" do
              form_with url: "/auth/developer", method: :post, data: {turbo: false} do |form|
                render Components::Button.new(label: "Developer login", href: "/auth/developer", variant: :primary, size: :lg)
              end
            end
          end
        end
      end
    end
  end

  private def render_flash
    if flash[:alert].present?
      render Components::AlertBanner.new(variant: :critical) do
        plain flash[:alert]
      end
    end
    if flash[:notice].present?
      render Components::AlertBanner.new(variant: :success) do
        plain flash[:notice]
      end
    end
  end
end
