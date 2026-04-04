# frozen_string_literal: true

class Views::Conversations::Index < Views::Base
  prop :user, User
  prop :conversations, ActiveRecord::Relation(Conversation)
  prop :search, String
  prop :params, _Any

  def view_template
    render Views::Layouts::Application.new title: ::Conversation.pn, return_href: messages_path, user: @user, nav_active: :messages, nav_alerts: [] do
      Column justify: "between", class: %w[grow-1] do
        Column do
          Row justify: "between" do
            Messages::TabBar user: @user, active: :conversations
            Search url: conversations_path, search: @search
          end
          Messages::ConversationsGrid user: @user, conversations: @conversations
        end
        Row justify: "between" do
          Button label: t(".new_conversation"), variant: :primary, size: :sm, tag: :a, href: new_conversation_path
          Paginate records: @conversations, params: @params
        end
      end
    end
  end
end
