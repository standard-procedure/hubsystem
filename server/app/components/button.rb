# frozen_string_literal: true

class Components::Button < Components::Base
  prop :label, _String?, default: nil
  prop :variant, Enum(:primary, :secondary, :danger, :ghost), default: :primary
  prop :size, Enum(:sm, :md, :lg), default: :md
  prop :tag, Enum(:button, :a), default: :button
  prop :href, _String?, default: nil
  prop :disabled, _Boolean, default: false
  prop :attributes, Hash, :**, default: {}.freeze

  def view_template(&)
    (@tag == :a) ? render_link(&) : render_button(&)
  end

  private def render_link(&) = a(class: class_list, href: @href, **@attributes) { contents(&) }
  private def render_button(&) = button(class: class_list, disabled: @disabled, **@attributes) { contents(&) }
  private def contents(&rendering) = rendering&.call || plain(@label)
  private def class_list
    classes = ["btn", "btn-#{@variant}"]
    classes << "btn-#{@size}" unless @size == :md
    classes.join(" ")
  end
end
