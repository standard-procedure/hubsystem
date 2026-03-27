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

  prop :justify, Enum(*JUSTIFY.keys), default: "start"
  prop :align, Enum(*ALIGN.keys), default: "stretch"
  prop :gap, Enum(*GAP.keys), default: 2
  prop :attributes, Hash, :**, default: {}.freeze

  def view_template(&)
    div(**mix(class: flex_classes, **@attributes), &)
  end

  private def direction_classes = raise(NotImplementedError)

  private def flex_classes = ["flex", *direction_classes, JUSTIFY.fetch(@justify), ALIGN.fetch(@align), GAP.fetch(@gap)]
end
