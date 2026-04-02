# frozen_string_literal: true

class Components::StatusItem < Components::Base
  STATUSES = {critical: "status-dot--red", warning: "status-dot--amber", alert: "status-dot--blue", online: "status-dot--green", offline: "status-dot--dark"}.freeze

  prop :state, OneOf(STATUSES.keys), default: :offline
  prop :label, _String?, default: nil
  prop :href, _String?

  def view_template(&)
    @href.blank? ? render_item(&) : render_link(&)
  end

  private def render_item(&)
    div class: %w[status-item] do
      render_contents(&)
    end
  end

  private def render_link(&)
    a href: @href, class: %w[status-item] do
      render_contents(&)
    end
  end

  private def render_contents(&block)
    div class: ["status-dot", STATUSES[@state]]
    block.nil? ? plain(@label.to_s) : block.call
  end
end
