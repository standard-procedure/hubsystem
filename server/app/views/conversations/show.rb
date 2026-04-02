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
          Row justify: "between" do
            StatusBar do |status|
              @conversation.users.each do |user|
                status.item label: user.to_s, state: @user.status_badge.to_sym
              end
            end
            Search url: conversation_path(@conversation), search: @search
          end
          MessagesGrid user: @user, messages: @messages
        end
        Column do
          Row justify: "end" do
            Paginate records: @messages, params: @params
          end
          Row justify: "between" do
            span { Button label: "Close Conversation", variant: :danger, size: :sm, tag: :a, href: new_conversation_closure_path(@conversation) if @conversation.active? }
            form_with model: @conversation.messages.build, url: conversation_messages_path(@conversation), method: :post do |form|
              Row justify: "between", wrap: false, gap: 2 do
                form.text_field :contents, placeholder: t(".send_message"), autofocus: true, required: true, class: %w[input-field grow-1]
                Button label: t(".send"), variant: :primary, size: :sm
              end
            end
          end
        end
      end
    end
  end
end
