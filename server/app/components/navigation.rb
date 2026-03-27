# frozen_string_literal: true

class Components::Navigation < Components::Slotted
  class Item < Literal::Data
    extend Components::Types

    prop :active, _Boolean, default: false
    prop :icon, _String?, default: "\u25CF"
    prop :label, String, default: ""
    prop :href, _String?
    prop :attributes, Hash, :**, default: {}.freeze

    def item_class = @active ? %w[nav-item nav-item--active] : %w[nav-item]
  end

  def initialize(...)
    @items = []
    super
  end

  def item(active: false, icon: "\u25CF", label: "", href: nil, **attributes)
    @items << Item.new(active:, icon:, label:, href:, attributes:)
  end

  def view_template
    div class: "nav-rails" do
      @items.each { |item| item.href.present? ? render_item_link(item) : render_item(item) }
    end
  end

  private def render_item item
    div class: item.item_class do
      render_inside item
    end
  end

  private def render_item_link item
    a(**mix(href: item.href, class: [item.item_class, item.attributes.delete(:class)], **item.attributes)) do
      render_inside item
    end
  end

  private def render_inside item
    span(class: "nav-icon") { item.icon }
    span(class: "nav-label") { item.label }
  end
end
