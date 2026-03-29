# frozen_string_literal: true

class UserActivityRefreshJob < ApplicationJob
  queue_as :default

  def perform
    users = User.active.in_order
    Turbo::StreamsChannel.broadcast_replace_to(
      :user_activity_matrix,
      target: "user_activity_matrix",
      renderable: Components::UserActivityMatrix.new(users: users)
    )
  end
end
