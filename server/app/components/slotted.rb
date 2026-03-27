# frozen_string_literal: true

class Components::Slotted < Components::Base
  def initialize(...)
    @vanishing = false
    super
  end
  attr_reader :vanishing

  def before_template(&)
    @vanishing = true
    vanish(&)
    super
    @vanishing = false
  end
end
