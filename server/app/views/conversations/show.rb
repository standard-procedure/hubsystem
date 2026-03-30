# frozen_string_literal: true

class Views::Conversations::Show < Views::Base
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::TurboStreamFrom

  prop :user, User
  prop :conversation, Conversation

  def view_template
    render Views::Layouts::Application.new(title: @conversation.subject, return_href: conversations_path, user: @user, active_nav: :messages) do
      turbo_stream_from @conversation
      render Components::Panel.new(title: @conversation.subject) do
        render_status_bar
        render_messages
        render_actions
      end
    end
  end

  private

  def render_status_bar
    Row justify: "between", align: "center" do
      span do
        Button label: "Close Conversation", variant: :danger, size: :sm, tag: :a, href: new_conversation_closure_path(@conversation) if @conversation.active?
      end
      StatusBar do |status|
        status.item label: @conversation.other_participant(@user).name, state: @user.state_color
        status.item label: @conversation.status.capitalize, state: status_state
      end
    end
  end

  def render_messages
    MessagesGrid user: @user, conversation: @conversation
  end

  def render_actions
    if @conversation.requested? && @conversation.recipient == @user
      Row justify: "end", gap: 8 do
        form_with url: conversation_acceptance_path(@conversation), method: :post do
          Button label: "Accept", variant: :primary
        end
        form_with url: conversation_rejection_path(@conversation), method: :post do
          Button label: "Reject", variant: :danger
        end
      end
    elsif @conversation.active?
      form_with url: conversation_messages_path(@conversation), method: :post do |form|
        Row gap: 4, align: "end" do
          div(style: "flex: 1") do
            input(
              name: "message[content]",
              placeholder: "Type your message...",
              rows: 2,
              required: true,
              class: "input-field",
              autofocus: true
            )
          end
          Button label: "Send", variant: :primary, size: :sm
        end
      end
    end
  end

  def message_classes(message)
    css = ["message"]
    css << "message--own" if message.sender == @user
    css.join(" ")
  end

  def status_state
    case @conversation.status
    when "active" then :nominal
    when "requested" then :warning
    when "closed" then :offline
    end
  end
end
