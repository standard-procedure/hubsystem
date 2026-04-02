# frozen_string_literal: true

class Components::StatusMatrix < Components::Slotted
  class Item < Literal::Data
    extend Components::Types

    STATUSES = {critical: "matrix-cell--red", warning: "matrix-cell--amber", alert: "matrix-cell--blue", online: "matrix-cell--green", offline: "matrix-cell--dark"}.freeze

    prop :state, OneOf(STATUSES.keys), default: :online
    prop :href, _String?
    prop :attributes, Hash, :**, default: {}.freeze

    def cell_class = STATUSES[@state]
  end

  def initialize(...)
    @items = []
    super
  end

  def item(state: :online, href: nil, **attributes)
    @items << Item.new(state:, href:, attributes:)
  end

  def view_template
    div class: "status-matrix" do
      @items.each { |item| item.href.present? ? render_item_link(item) : render_item(item) }
    end
  end

  private def render_item item
    div class: ["matrix-cell", item.cell_class]
  end

  private def render_item_link item
    a(**mix(href: item.href, class: ["matrix-cell", item.cell_class, item.attributes.delete(:class)], **item.attributes)) do
      render_item item
    end
  end
end
