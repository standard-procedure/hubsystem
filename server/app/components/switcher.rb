# frozen_string_literal: true

class Components::Switcher < Components::FlexContainer
  JUSTIFY_MD = {
    "start" => "@md:justify-start",
    "end" => "@md:justify-end",
    "center" => "@md:justify-center",
    "between" => "@md:justify-between",
    "around" => "@md:justify-around",
    "evenly" => "@md:justify-evenly",
    "stretch" => "@md:justify-stretch",
    "normal" => "@md:justify-normal"
  }.freeze

  ALIGN_MD = {
    "start" => "@md:items-start",
    "end" => "@md:items-end",
    "center" => "@md:items-center",
    "stretch" => "@md:items-stretch",
    "baseline" => "@md:items-baseline"
  }.freeze
  prop :justify_md, Enum(*JUSTIFY_MD.keys), default: "between"
  prop :align_md, Enum(*ALIGN_MD.keys), default: "start"

  def view_template(&)
    div(class: "@container") do
      super
    end
  end

  private def direction_classes = %w[flex-col flex-wrap @md:flex-row] + [JUSTIFY_MD[@justify_md], ALIGN_MD[@align_md]]
end
