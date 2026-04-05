# frozen_string_literal: true

class HubSystem::SecurityPass < HubSystem::ApplicationRecord
  include ::HasAttributes

  Unauthorised = Class.new(StandardError)

  belongs_to :resource, polymorphic: true
  belongs_to :user, polymorphic: true
  enum :status, locked: 0, unlocked: 100

  has_attribute :commands, :string, default: "[]"

  def unlock(*requests, &block)
    authorise!(*requests)
    unlocked!
    block.call(resource)
  ensure
    locked!
  end

  def authorise!(*requests)
    raise Unauthorised, "#{user} not authorised for #{requests} on #{resource}" unless authorised?(*requests)
  end

  def allows?(*requests)
    cmds = parsed_commands
    cmds.empty? || (requests.map(&:to_s) - cmds).empty?
  end

  def authorised?(*requests)
    raise NotImplementedError, "subclasses must implement authorised?"
  end

  private

  def parsed_commands
    JSON.parse(commands || "[]")
  rescue JSON::ParserError
    []
  end
end
