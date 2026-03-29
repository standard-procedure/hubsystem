# frozen_string_literal: true

class Components::StatusItem < Components::Base
  STATUSES = {critical: "status-dot--red", warning: "status-dot--amber", info: "status-dot--blue", nominal: "status-dot--green", offline: "status-dot--dark"}.freeze

  prop :state, Enum(STATUSES.keys), default: :nominal
  prop :label, _String?, default: nil

  def view_template(&block)
    div class: "status-item" do
      div class: ["status-dot", STATUSES[@state]]
      if block
        yield
      else
        plain @label.to_s
      end
    end
  end
end
