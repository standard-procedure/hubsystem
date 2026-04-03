# frozen_string_literal: true

module Components::MainNavigation
  include Components::Types
  extend Literal::Types
  include HasTypeChecks

  def self.Location = OneOf(LOCATIONS.keys)
  def self.Locations = SomeOf(*LOCATIONS.keys)
  def self.LocationStatus = OneOf(:nominal, :active, :alert)

  def self.each(active: :dashboard, alerts: [], &visitor)
    _check active, is: self.Location
    _check alerts, is: self.Locations
    _check visitor, is: _Callable

    LOCATIONS.keys.each do |location|
      visitor.call name: location, label: label_for(location), href: href_for(location), status: status_for(location, active, alerts)
    end
  end

  def self.label_for location
    I18n.t("application.#{location}")
  end

  def self.href_for location
    Rails.application.routes.url_helpers.send LOCATIONS[location]
  end

  def self.status_for location, active, alerts
    return :alert if alerts.include? location
    return :active if active == location
    :nominal
  end

  LOCATIONS = {dashboard: :root_path, messages: :messages_path, projects: :root_path, terminals: :root_path, settings: :component_path}.freeze
end
