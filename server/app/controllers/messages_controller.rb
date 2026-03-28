class MessagesController < ApplicationController
  def index
    redirect_to conversations_path
  end
end
