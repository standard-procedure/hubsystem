# frozen_string_literal: true

class Components::NavigationPanel < Components::Base
  prop :active, MainNavigation.Location, default: :dashboard
  prop :alerts, MainNavigation.Locations, default: [].freeze

  def view_template
    div class: %w[nav-panel flex flex-row grow-1] do
      Navigation do |nav|
        MainNavigation.each active: @active, alerts: @alerts do |name:, label:, href:, status:|
          nav.item active: status == :active, alert: status == :alert, label: label, href: href
        end
      end
      yield if block_given?
    end
  end
end
