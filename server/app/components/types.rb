# frozen_string_literal: true

module Components::Types
  def self.Enum(*values) = proc { |v| values.flatten.include? v }
end
