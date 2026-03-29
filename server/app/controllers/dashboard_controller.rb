class DashboardController < ApplicationController
  def show
    @conversations = Conversation.involving(Current.user)
      .where(status: [:requested, :active])
      .or(Conversation.involving(Current.user).recently_closed)
      .includes(:initiator, :recipient)
    @tasks = Task.assigned_to(Current.user).open.includes(:dependencies)
    render Views::Dashboard::Show.new(user: Current.user, conversations: @conversations, tasks: @tasks)
  end
end
