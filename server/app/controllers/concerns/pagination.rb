module Pagination
  extend ActiveSupport::Concern

  private def page_number = params[:page]
end
