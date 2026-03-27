# frozen_string_literal: true

class Components::Column < Components::FlexContainer
  prop :align, Enum(*ALIGN.keys), default: "stretch"

  private def direction_classes = ["flex-col"]
end
