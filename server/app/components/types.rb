# frozen_string_literal: true

module Components::Types
  def Enum(*values) = proc { values.flatten.include?(it) }
end
