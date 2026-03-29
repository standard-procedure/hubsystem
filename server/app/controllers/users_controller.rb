# frozen_string_literal: true

class UsersController < ApplicationController
  PER_PAGE = 20

  def index
    scope = User.active.in_order
    scope = scope.search_by_name_or_uid(params[:q]) if params[:q].present?
    @page = [params[:page].to_i, 1].max
    @total_pages = (scope.count.to_f / PER_PAGE).ceil
    @users = scope.offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
    @active_conversation_user_ids = Conversation.open.involving(Current.user).pluck(:initiator_id, :recipient_id).flatten.uniq - [Current.user.id]
    render Views::Users::Index.new(users: @users, page: @page, total_pages: @total_pages, query: params[:q], active_conversation_user_ids: @active_conversation_user_ids)
  end

  def show
    @user = User.find(params[:id])
    @notes = @user.notes_about.visible_to(Current.user).recent
    render Views::Users::Show.new(user: @user, notes: @notes)
  end
end
