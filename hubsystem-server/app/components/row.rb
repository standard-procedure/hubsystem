# frozen_string_literal: true

class Components::Row < Components::FlexContainer
  prop :align, Components::Types.Enum(*ALIGN.keys), default: "center"
  prop :wrap, _Boolean, default: true

  private

  def direction_classes
    ["flex-row", @wrap ? "flex-wrap" : "flex-nowrap"]
  end
end
