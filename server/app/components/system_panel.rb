# frozen_string_literal: true

class Components::SystemPanel < Components::Base
  STATUSES = Components::StatusItem::STATUSES

  prop :title, String
  prop :subtitle, String, default: ""
  prop :header_text, String, default: "HubSystem"
  prop :header_status_text, String, default: -> { I18n.l Time.current, format: :short }
  prop :header_status, OneOf(STATUSES.keys), default: :online

  def view_template(&content)
    div class: "sys-header" do
      div class: "sys-status-bar"
      div class: "sys-header-bar" do
        span { @header_text }
        render Components::StatusItem.new(state: @header_status, label: @header_status_text)
      end
      div class: "sys-header-content" do
        div(class: "sys-title") { @title }
        div(class: "sys-subtitle") { @subtitle }
        content&.call
      end
    end
  end
end
