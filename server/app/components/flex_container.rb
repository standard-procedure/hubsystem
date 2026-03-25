# frozen_string_literal: true

class Components::FlexContainer < Components::Base
  JUSTIFY = {
    "start" => "justify-start",
    "end" => "justify-end",
    "center" => "justify-center",
    "between" => "justify-between",
    "around" => "justify-around",
    "evenly" => "justify-evenly",
    "stretch" => "justify-stretch",
    "normal" => "justify-normal"
  }.freeze

  ALIGN = {
    "start" => "items-start",
    "end" => "items-end",
    "center" => "items-center",
    "stretch" => "items-stretch",
    "baseline" => "items-baseline"
  }.freeze

  GAP = {
    0 => "gap-0", 1 => "gap-1", 2 => "gap-2", 3 => "gap-3", 4 => "gap-4",
    5 => "gap-5", 6 => "gap-6", 7 => "gap-7", 8 => "gap-8"
  }.freeze

  prop :justify, Components::Types.Enum(*JUSTIFY.keys), default: "start"
  prop :align, Components::Types.Enum(*ALIGN.keys), default: "stretch"
  prop :gap, Components::Types.Enum(*GAP.keys), default: 1
  prop :attributes, Hash, :**, default: {}.freeze

  def view_template(&)
    div class: "@container" do
      div(**mix(class: flex_classes, **@attributes), &)
    end
  end

  private

  def direction_classes = raise NotImplementedError

  def flex_classes
    [
      "flex",
      *direction_classes,
      JUSTIFY.fetch(@justify),
      ALIGN.fetch(@align),
      GAP.fetch(@gap)
    ]
  end
end
