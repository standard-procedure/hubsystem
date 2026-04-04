# frozen_string_literal: true

class Components::Button < Components::Base
  prop :label, _String?, default: nil
  prop :variant, OneOf(:primary, :secondary, :danger, :ghost), default: :primary
  prop :size, OneOf(:sm, :md, :lg), default: :md
  prop :href, _String?, default: nil
  prop :disabled, _Boolean, default: false
  prop :type, String, default: "submit"
  prop :attributes, Hash, :**, default: {}.freeze

  def view_template(&)
    @href ? render_link(&) : render_button(&)
  end

  private def render_link(&) = a(class: class_list, href: @href, **@attributes) { contents(&) }
  private def render_button(&) = button(class: class_list, type: @type, disabled: @disabled, **@attributes) { contents(&) }
  private def contents(&rendering) = rendering&.call || plain(@label)
  private def class_list = ["btn", "btn-#{@variant}", ("btn-#{@size}" unless @size == :md)]
end
