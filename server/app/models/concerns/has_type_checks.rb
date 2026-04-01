module HasTypeChecks
  extend ActiveSupport::Concern

  class_methods do
    def _check value, is:
      raise ArgumentError.new("#{value} fails type check #{is}") unless is === value
    end
  end

  def _check(value, is:) = self.class._check(value, is:)
end
