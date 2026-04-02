# frozen_string_literal: true

class Components::CrtMonitor < Components::Base
  prop :title, String, default: "HubSystem"
  prop :return_href, _String?, default: nil
  prop :user, _Any?, default: nil
  prop :active, MainNavigation.Location, default: :dashboard
  prop :alerts, MainNavigation.Locations, default: [].freeze

  def view_template(&)
    div class: "crt-housing" do
      render_top
      div class: "crt-bezel" do
        div class: "crt-screen" do
          main(class: "screen-content") do
            NavigationPanel(active: @active, alerts: @alerts, &)
          end
        end
      end
      render_bottom
    end
  end

  private def render_top
    div class: "crt-top" do
      div class: "crt-top-inner" do
        div class: "crt-brand-group" do
          if @return_href.present?
            a(href: @return_href, class: "crt-back") { "\u2190" }
            a(href: @return_href, class: "crt-brand") { @title }
          else
            a(href: root_path, class: "crt-brand") { @title }
          end
        end
        if @user
          a href: logout_path, class: "crt-badge", data_turbo_method: :delete do
            div class: "crt-badge-led"
            span(class: "crt-badge-text") { t("application.logout") }
          end
        end
      end
      div class: "crt-vents" do
        12.times { div(class: "crt-vent") }
      end
    end
  end

  private def render_bottom
    div class: "crt-bottom" do
      div class: "crt-bottom-inner" do
        div class: "crt-controls" do
          MainNavigation.each active: @active, alerts: @alerts do |name:, label:, href:, status:|
            a href: href, class: ["crt-button", ("crt-button--active" if status == :active), ("crt-button--alert" if status == :alert)], title: label
          end
        end
        div class: "crt-nameplate" do
          span(class: "crt-nameplate-text") { "MU/TH/UR 6000" }
        end
      end
    end
  end
end
