class DashboardController < ApplicationController
  def show
    @unread_messages = Current.user.unread_messages
    @all_users = User.active.in_order
    render Views::Dashboard::Show.new(user: Current.user, unread_messages: @unread_messages, all_users: @all_users)
  end
end
