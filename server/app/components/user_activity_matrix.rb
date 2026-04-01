# frozen_string_literal: true

class Components::UserActivityMatrix < Components::Base
  include Phlex::Rails::Helpers::TurboStreamFrom

  prop :users, _Any, default: [].freeze

  def view_template
    div id: "user_activity_matrix" do
      turbo_stream_from(:user_activity_matrix)
      StatusMatrix do |matrix|
        @users.each do |user|
          matrix.item state: user.status_badge.to_sym, href: user_path(user)
        end
      end
    end
  end
end
