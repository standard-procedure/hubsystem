# frozen_string_literal: true

class Synthetic::MessageProcessorJob < ApplicationJob
  queue_as :default

  def perform(message, user)
    raise ArgumentError unless Message === message
    raise ArgumentError unless User === user
    return unless user&.synthetic?

    user.role.receive message
  end
end
