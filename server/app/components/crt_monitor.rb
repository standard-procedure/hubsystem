# frozen_string_literal: true

class Components::CrtMonitor < Components::Base
  prop :brand, String, default: "HubSystem"
  prop :user, _Any?, default: nil
  prop :active_nav, Enum(:dashboard, :messages, :system), default: :dashboard

  def view_template(&)
    div class: "crt-housing" do
      render_top
      div class: "crt-bezel" do
        div class: "crt-screen" do
          main(class: "screen-content", &)
        end
      end
      render_bottom
    end
  end

  private

  def render_top
    div class: "crt-top" do
      div class: "crt-top-inner" do
        span(class: "crt-brand") { @brand }
        if @user
          a href: logout_path, class: "crt-badge" do
            div class: "crt-badge-led"
            span(class: "crt-badge-text") { "Power" }
          end
        end
      end
      div class: "crt-vents" do
        12.times { div(class: "crt-vent") }
      end
    end
  end

  def nav_knob(name, label, href = nil)
    css = "crt-knob"
    css += " crt-knob--power" if @active_nav == name
    if href
      a(href: href, class: css, title: label)
    else
      div(class: css, title: label)
    end
  end

  def render_bottom
    div class: "crt-bottom" do
      div class: "crt-bottom-inner" do
        div class: "crt-controls" do
          nav_knob :dashboard, "Dashboard", root_path
          nav_knob :messages, "Messages", conversations_path
          nav_knob :system, "System"
        end
        div class: "crt-nameplate" do
          span(class: "crt-nameplate-text") { "MU/TH/UR 6000" }
        end
      end
    end
  end
end
