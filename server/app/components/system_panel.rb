# frozen_string_literal: true

class Components::SystemPanel < Components::Base
  prop :title, String
  prop :subtitle, String
  prop :header_text, String, default: "HubSystem"
  prop :header_status, String, default: -> { I18n.l Time.current, format: :short }

  def view_template(&content)
    div class: "sys-header" do
      div class: "sys-status-bar"
      div class: "sys-header-bar" do
        span { @header_text }
        span { @header_status }
      end
      div class: "sys-header-content" do
        div(class: "sys-title") { @title }
        div(class: "sys-subtitle") { @subtitle }
        content&.call
      end
    end
  end
end
