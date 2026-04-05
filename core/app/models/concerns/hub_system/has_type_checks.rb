# frozen_string_literal: true

module HubSystem::HasTypeChecks
  extend ActiveSupport::Concern

  included do
    extend HubSystem::HasTypeChecks
  end

  def _check(value, is:)
    raise ArgumentError, "#{value} fails type check #{is}" unless is === value
  end
end
