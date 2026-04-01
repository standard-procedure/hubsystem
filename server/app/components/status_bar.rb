# frozen_string_literal: true

class Components::StatusBar < Components::Slotted
  class Item < Literal::Data
    extend Components::Types

    STATUSES = {critical: "status-dot--red", warning: "status-dot--amber", alert: "status-dot--blue", online: "status-dot--green", offline: "status-dot--dark"}.freeze

    prop :state, Enum(STATUSES.keys), default: :offline
    prop :label, _String?
    prop :contents, _Callable?

    def dot_class = STATUSES[@state]
  end

  def initialize(...)
    @items = []
    super
  end

  def item(state: :offline, label: nil, &contents)
    @items << Item.new(state:, label:, contents:)
  end

  def view_template
    div class: "status-bar" do
      @items.each { |item| render_item(item) }
    end
  end

  private def render_item(item)
    if item.contents
      render(Components::StatusItem.new(state: item.state), &item.contents)
    else
      render Components::StatusItem.new(state: item.state, label: item.label)
    end
  end
end
