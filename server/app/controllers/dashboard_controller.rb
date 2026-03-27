class DashboardController < ApplicationController
  def show
    render Views::Dashboard::Show.new(user: Current.user)
  end
end
