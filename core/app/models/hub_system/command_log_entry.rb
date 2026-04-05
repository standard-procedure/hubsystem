# frozen_string_literal: true

class HubSystem::CommandLogEntry < HubSystem::ApplicationRecord
  belongs_to :actor, polymorphic: true
  enum :status, started: 0, completed: 1, failed: -1
end
