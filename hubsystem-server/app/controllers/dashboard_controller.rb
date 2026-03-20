class DashboardController < ApplicationController
  def show
    render Views::Dashboard::Show
  end
end
