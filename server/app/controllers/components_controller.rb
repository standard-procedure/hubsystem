class ComponentsController < ApplicationController
  def show
    render Views::Components::Show.new(user: Current.user)
  end
end
