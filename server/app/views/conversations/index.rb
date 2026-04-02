# frozen_string_literal: true

class Views::Conversations::Index < Views::Base
  prop :user, User
  prop :conversations, ActiveRecord::Relation(Conversation)
  prop :search, String
  prop :params, _Any

  def view_template
    render Views::Layouts::Application.new title: t(".title"), return_href: root_path, user: @user, nav_active: :messages, nav_alerts: [] do
      Column justify: "between", class: %w[grow-1] do
        Column do
          Row justify: "between" do
            StatusBar do |tabs|
              tabs.item state: :offline, href: messages_path, label: t(".inbox")
              tabs.item state: :online, href: conversations_path, label: t(".conversations")
            end
            Search url: conversations_path, search: @search
          end
          ConversationsGrid user: @user, conversations: @conversations
        end
        Row justify: "end" do
          Paginate records: @conversations, params: @params
        end
      end
    end
  end
end
