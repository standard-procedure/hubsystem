# frozen_string_literal: true

class Views::Dashboard::Show < Views::Base
  def view_template
    render Views::Layouts::Application.new(title: "HubSystem") do
      div class: "sys-header" do
        div class: "sys-status-bar"
        div class: "sys-header-bar" do
          span { "Interface Systems Division" }
          span { "MU/TH/UR 6000 — Active" }
        end
        div class: "sys-header-content" do
          div(class: "sys-title") { "HubSystem" }
          div(class: "sys-subtitle") { "Human \u2194 Agent Interface Protocol" }
        end
      end

      render Components::Panel.new(title: "System Status", variant: :active) do
        div style: "margin-bottom: 24px;" do
          div(class: "boot-line", style: "animation-delay: 0.1s") { "HUBSYSTEM INTERFACE TERMINAL v1.0" }
          div(class: "boot-line boot-line--dim", style: "animation-delay: 0.3s") { "MU/TH/UR 6000 BIOS rev 4.2.1" }
          div(class: "boot-line boot-line--dim", style: "animation-delay: 0.5s") { "Memory test... 131072K OK" }
          div(class: "boot-line boot-line--dim", style: "animation-delay: 0.7s") { "Initialising agent subsystem... 8 slots available" }
          div(class: "boot-line boot-line--dim", style: "animation-delay: 0.9s") { "Network link established \u2014 latency 12ms" }
          div(class: "boot-line", style: "animation-delay: 1.1s") do
            plain "SYSTEM READY"
            span(class: "cursor")
          end
        end
      end

      render Components::Panel.new(title: "Agent Roster") do
        p(style: "color: var(--color-text-muted); font-size: 13px;") { "No agents currently deployed." }
      end
    end
  end
end
