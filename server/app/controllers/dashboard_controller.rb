class DashboardController < ApplicationController
  def show
    @conversations = Conversation.involving(Current.user)
      .where(status: [:requested, :active])
      .or(Conversation.involving(Current.user).recently_closed)
    render Views::Dashboard::Show.new(user: Current.user, conversations: @conversations)
  end
end
