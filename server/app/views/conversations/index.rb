# frozen_string_literal: true

class Views::Conversations::Index < Views::Base
  prop :user, User
  prop :conversations, ActiveRecord::Relation(Conversation)
  prop :search, String
  prop :archive, _Boolean, default: false
  prop :params, _Any

  def view_template
    render Views::Layouts::Application.new title: ::Conversation.pn, return_href: messages_path, user: @user, nav_active: :messages, nav_alerts: [] do
      Column justify: "between", class: %w[grow-1] do
        Column do
          Switcher do
            Messages::TabBar user: @user, active: @archive ? :archive : :conversations
            Row gap: 2, wrap: false do
              Search url: conversations_path, search: @search, placeholder: t(".search_placeholder")
              Button label: t(".new_conversation"), variant: :primary, size: :sm, tag: :a, href: new_conversation_path
            end
          end
          if @conversations.any?
            Messages::ConversationsGrid user: @user, conversations: @conversations
          else
            render_empty_state
          end
        end
        Row justify: "end" do
          Paginate records: @conversations, params: @params
        end
      end
    end
  end

  private

  def render_empty_state
    Panel(title: t(".empty_title"), variant: :default) do
      p(class: "text-muted") { @archive ? t(".empty_archived") : t(".empty_active") }
    end
  end
end
