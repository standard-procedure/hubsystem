# frozen_string_literal: true

module HasStatusBadge
  extend ActiveSupport::Concern

  included do
    enum :status_badge, offline: 0, online: 10, alert: 20, warning: 30, critical: 50
  end
end
