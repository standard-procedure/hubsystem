# frozen_string_literal: true

module Components::Types
  extend ActiveSupport::Concern

  included do
    extend Components::Types
  end

  def OneOf(*values) = proc { values.flatten.include?(it) }
  def SomeOf(*values) = proc { it.flatten.all? { |i| values.flatten.include? i } }
end
