# frozen_string_literal: true

class Components::StatusItem < Components::Base
  STATUSES = {critical: "status-dot--red", warning: "status-dot--amber", alert: "status-dot--blue", online: "status-dot--green", offline: "status-dot--dark"}.freeze

  prop :state, OneOf(STATUSES.keys), default: :offline
  prop :label, _String?, default: nil

  def view_template(&block)
    div class: "status-item" do
      div class: ["status-dot", STATUSES[@state]]
      block.nil? ? plain(@label.to_s) : block.call
    end
  end
end
