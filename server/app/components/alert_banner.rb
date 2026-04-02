# frozen_string_literal: true

class Components::AlertBanner < Components::Base
  DEFAULT_ICONS = {critical: "\u25B2", warning: "\u25B2", info: "\u25CF", success: "\u2713"}.freeze

  prop :variant, OneOf(:critical, :warning, :info, :success), default: :info
  prop :icon, _String?, default: nil

  def view_template(&)
    div class: "alert-banner alert-banner--#{@variant}" do
      span(class: "alert-icon") { @icon || DEFAULT_ICONS[@variant] }
      span(&)
    end
  end
end
