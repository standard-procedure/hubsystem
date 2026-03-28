class DashboardController < ApplicationController
  def show
    @conversations = Conversation.involving(Current.user)
      .where(status: [:requested, :active])
      .or(Conversation.involving(Current.user).recently_closed)
    @tasks = Task.assigned_to(Current.user).where.not(status: [:completed, :cancelled])
    render Views::Dashboard::Show.new(user: Current.user, conversations: @conversations, tasks: @tasks)
  end
end
