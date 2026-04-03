# frozen_string_literal: true

module CableClient
  include ActionCable::TestHelper

  def cable_broadcasts_for(user)
    stream = NotificationsChannel.broadcasting_for(user)
    broadcasts(stream).map do |raw|
      raw.is_a?(String) ? JSON.parse(raw) : raw
    end
  end

  def cable_received_event?(user, event)
    cable_broadcasts_for(user).any? { |b| b["event"] == event }
  end

  def clear_cable_broadcasts_for(user)
    stream = NotificationsChannel.broadcasting_for(user)
    broadcasts(stream).clear
  end
end
