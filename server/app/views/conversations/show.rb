# frozen_string_literal: true

class Views::Conversations::Show < Views::Base
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::TurboStreamFrom

  prop :user, User
  prop :conversation, Conversation
  prop :messages, ActiveRecord::Relation(Conversation::Message)
  prop :search, String, default: ""
  prop :params, _Any

  def view_template
    render Views::Layouts::Application.new(title: @conversation.subject, return_href: conversations_path, user: @user, nav_active: :messages, nav_alerts: []) do
      turbo_stream_from @conversation
      Column justify: "between", class: %w[grow-1] do
        Column do
          Switcher do
            Messages::TabBar user: @user, active: :conversations
            Search url: conversation_path(@conversation), search: @search
          end
          Messages::MessagesGrid user: @user, messages: @messages, show_subject: false
        end
        Column do
          Switcher do
            Users::TabBar user: @user, users: @conversation.users
            Paginate records: @messages, params: @params
          end
          Row justify: "between", gap: 4 do
            if @conversation.active?
              form_with url: conversation_closure_path(@conversation), method: :post do
                Button label: Conversation::Message.an(:close_conversation), variant: :ghost, size: :sm, data: {turbo_confirm: t(".confirm_close_conversation")}
              end
            end
            form_with model: @conversation.messages.build, url: conversation_messages_path(@conversation), method: :post, class: %w[grow-1] do |form|
              Row justify: "between", wrap: false, gap: 2 do
                form.text_field :contents, placeholder: t(".send_message_placeholder"), autofocus: true, required: true, class: %w[input-field grow-1]
                Button label: Conversation::Message.an(:send_message), variant: :primary, size: :sm
              end
            end
          end
        end
      end
    end
  end
end
