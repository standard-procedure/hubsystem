# frozen_string_literal: true

module HasNotifications
  extend ActiveSupport::Concern

  # Include in any model that should broadcast notifications via NotificationsChannel.
  #
  # The including model must implement:
  #   #notification_recipients — returns users to notify
  #   #notification_event      — returns the event name string (e.g. "message.created")
  #   #notification_payload    — returns a hash of additional fields (e.g. IDs)

  included do
    after_create_commit :broadcast_created_notification
    after_update_commit :broadcast_updated_notification
  end

  private

  def broadcast_created_notification
    broadcast_notification "#{notification_resource}.created"
  end

  def broadcast_updated_notification
    broadcast_notification "#{notification_resource}.updated"
  end

  def broadcast_notification(event)
    payload = {event:}.merge(notification_payload)
    notification_recipients.each do |user|
      NotificationsChannel.broadcast_to(user, payload)
    end
  end

  def notification_resource
    model_name.element
  end
end
