# frozen_string_literal: true

class Components::Button < Components::Base
  VARIANTS = Components::Types.Enum(:primary, :secondary, :danger, :ghost)
  SIZES = Components::Types.Enum(:sm, :md, :lg)
  TAGS = Components::Types.Enum(:button, :a)

  prop :label, _String?, default: nil
  prop :variant, VARIANTS, default: :primary
  prop :size, SIZES, default: :md
  prop :tag, TAGS, default: :button
  prop :href, _String?, default: nil
  prop :disabled, _Boolean, default: false
  prop :attributes, Hash, :**, default: {}.freeze

  def view_template(&)
    css_classes = class_list

    if @tag == :a
      a(class: css_classes, href: @href, **@attributes) { content(&) }
    else
      button(class: css_classes, disabled: @disabled, **@attributes) { content(&) }
    end
  end

  private

  def content(&)
    if block_given?
      yield
    elsif @label
      plain @label
    end
  end

  def class_list
    classes = ["btn", "btn-#{@variant}"]
    classes << "btn-#{@size}" unless @size == :md
    classes.join(" ")
  end
end
