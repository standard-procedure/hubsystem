# frozen_string_literal: true

class Views::Sessions::New < Views::Base
  include Phlex::Rails::Helpers::FormWith

  def view_template
    render Views::Layouts::Application.new(title: "HubSystem") do
      render_flash
      render Components::Panel.new(title: "Authentication Required", variant: :active) do
        form_with url: "/session", class: "space-y-4" do |f|
          div style: "margin-bottom: 16px;" do
            render Components::InputField.new(
              name: "email_address",
              type: "email",
              label: "Operator ID",
              placeholder: "operator@weyland-yutani.com"
            )
          end
          div style: "margin-bottom: 16px;" do
            render Components::InputField.new(
              name: "password",
              type: "password",
              label: "Access Code",
              placeholder: "Enter access code..."
            )
          end
          div do
            render Components::Button.new(label: "Authenticate", variant: :primary, size: :lg)
          end
        end
      end
    end
  end

  private

  def render_flash
    flash = helpers.flash
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
