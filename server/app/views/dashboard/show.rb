# frozen_string_literal: true

class Views::Dashboard::Show < Views::Base
  prop :user, User

  def view_template
    render Views::Layouts::Application.new(title: "HubSystem") do
      Components::SystemPanel(title: "Welcome back #{@user}", subtitle: "Human \u2194 Agent Interface Protocol") do
        Terminal do |terminal|
          terminal.bright_line { "HUBSYSTEM INTERFACE TERMINAL v1.0" }
          terminal.line { "MU/TH/UR 6000 BIOS rev 4.2.1" }
          terminal.line { "Memory test... 131072K OK" }
          terminal.line { "Initialising agent subsystem... 8 slots available" }
          terminal.line { "Network link established \u2014 latency 12ms" }
          terminal.bright_line do
            plain "SYSTEM READY"
            span(class: "cursor")
          end
        end
      end

      render Components::Panel.new(title: "Alerts and Buttons") do
        Switcher do
          Column do
            AlertBanner(variant: :critical) { "Critical error" }
            AlertBanner(variant: :warning) { "Alert: operating parameters reduced" }
            AlertBanner(variant: :info) { "Agents running" }
            AlertBanner(variant: :success) { "Sub agent task completed" }
          end
          Column do
            Button label: "Primary", variant: :primary
            Button label: "Secondary", variant: :secondary
            Button label: "Danger", variant: :danger
            Button label: "Ghost", variant: :ghost
          end
        end
      end

      render Components::Panel.new(title: "Status and Fields") do
        Switcher do
          Column do
            Row justify: "start", align: "start", gap: 16 do
              Navigation do |nav|
                nav.item label: "Agents", active: true, href: "#"
                nav.item label: "Channels", href: "#"
                nav.item label: "System"
                nav.item label: "Logs"
              end
              Column class: "grow-1", gap: 4 do
                StatusMatrix do |matrix|
                  matrix.item state: :nominal, href: "#"
                  matrix.item state: :critical
                  12.times { matrix.item state: [:nominal, :warning, :offline].sample }
                  matrix.item state: :warning, href: "#"
                  matrix.item state: :offline
                end
                StatusBar do |status|
                  status.item label: "3 Active", state: :nominal
                  status.item label: "1 Scannin", state: :info
                  status.item label: "1 Awaiting", state: :warning
                  status.item label: "1 Error", state: :critical
                  status.item label: "1 Offline", state: :offline
                end
              end
            end
          end
          Column class: "basis-sm" do
            Input name: "text", label: "Text Field", placeholder: "Type here", type: "text"
            Input name: "required", label: "Required Field", placeholder: "You must type here", type: "text", required: true
            Input name: "error", label: "That's not right", placeholder: "Try again", type: "number", error: "A different number", value: 22
          end
        end
      end
    end
  end
end
