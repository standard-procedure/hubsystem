# frozen_string_literal: true

class Components::CrtMonitor < Components::Base
  prop :brand, String, default: "HubSystem"
  prop :model, String, default: "Model MU/TH/UR 6000 — Interface Terminal"

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
        div class: "crt-badge" do
          div class: "crt-badge-led"
          span(class: "crt-badge-text") { "Power" }
        end
        span(class: "crt-model") { @model }
      end
      div class: "crt-vents" do
        12.times { div(class: "crt-vent") }
      end
    end
  end

  def render_bottom
    div class: "crt-bottom" do
      div class: "crt-bottom-inner" do
        div class: "crt-controls" do
          div(class: "crt-knob crt-knob--power")
          div(class: "crt-knob")
          div(class: "crt-knob")
          span(class: "crt-label") { "Brightness · Contrast · V-Hold" }
        end
        div class: "crt-nameplate" do
          span(class: "crt-nameplate-text") { "MU/TH/UR 6000" }
        end
      end
    end
  end
end
