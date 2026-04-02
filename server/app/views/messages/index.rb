# frozen_string_literal: true

class Views::Messages::Index < Views::Base
  prop :user, User
  prop :messages, ActiveRecord::Relation(Conversation::Message)
  prop :search, String
  prop :params, _Any

  def view_template
    render Views::Layouts::Application.new title: t(".title"), return_href: root_path, user: @user, nav_active: :messages, nav_alerts: [] do
      Column justify: "between", class: %w[grow-1] do
        Column do
          Row justify: "between" do
            StatusBar do |tabs|
              tabs.item state: :online, href: messages_path, label: t(".inbox")
              tabs.item state: :offline, href: conversations_path, label: t(".conversations")
            end
            Search url: messages_path, search: @search
          end
          MessagesGrid user: @user, messages: @messages
        end
        Row justify: "end" do
          Paginate records: @messages, params: @params
        end
      end
    end
  end
end
