# frozen_string_literal: true

class NotesController < ApplicationController
  before_action :set_user
  before_action :set_note, only: [:edit, :update, :destroy]
  before_action :authorize_author!, only: [:edit, :update, :destroy]

  def new
    render Views::Notes::New.new(user: @user)
  end

  def create
    @note = @user.notes_about.build(note_params.merge(author: Current.user))
    if @note.save
      redirect_to user_path(@user)
    else
      render Views::Notes::New.new(user: @user, note: @note)
    end
  end

  def edit
    render Views::Notes::Edit.new(user: @user, note: @note)
  end

  def update
    if @note.update(note_params)
      redirect_to user_path(@user)
    else
      render Views::Notes::Edit.new(user: @user, note: @note)
    end
  end

  def destroy
    @note.destroy
    redirect_to user_path(@user)
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_note
    @note = @user.notes_about.find(params[:id])
  end

  def authorize_author!
    redirect_to user_path(@user) unless @note.author == Current.user
  end

  def note_params
    params.require(:note).permit(:content, :visibility)
  end
end
