# frozen_string_literal: true

class Views::Messages::Index < Views::Base
  prop :user, User
  prop :unread_messages, ActiveRecord::Relation(Conversation::Message)

  def view_template
    render Views::Layouts::Application.new(title: t(".title"), return_href: root_path, user: @user, nav_active: :messages, nav_alerts: []) do
      Column justify: "between", class: %w[grow-1] do
      end
    end
  end
end
