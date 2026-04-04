module HasTypeChecks
  extend ActiveSupport::Concern

  included do
    extend HasTypeChecks
  end

  def _check(value, is:)
    raise ArgumentError.new("#{value} fails type check #{is}") unless is === value
  end
end
