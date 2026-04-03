# frozen_string_literal: true

class Components::Users::TabBar < Components::Base
  prop :user, User
  prop :users, ActiveRecord::Relation(User)

  def view_template
    StatusBar do |status|
      @users.each do |user|
        status.item label: user.to_s, state: @user.status_badge.to_sym
      end
    end
  end
end
