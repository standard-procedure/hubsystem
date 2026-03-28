# frozen_string_literal: true

class Views::Conversations::Show < Views::Base
  include Phlex::Rails::Helpers::FormWith

  prop :user, User
  prop :conversation, Conversation

  def view_template
    render Views::Layouts::Application.new(title: "HubSystem", user: @user, active_nav: :messages) do
      render Components::Panel.new(title: @conversation.subject) do
        render_status_bar
        render_messages
        render_actions
      end
    end
  end

  private

  def render_status_bar
    StatusBar do |status|
      status.item label: @conversation.other_participant(@user).name, state: :info
      status.item label: @conversation.status.capitalize, state: status_state
    end
  end

  def render_messages
    div class: "message-list" do
      @conversation.messages.order(:created_at).each do |message|
        div class: message_classes(message) do
          span(class: "message-sender") { message.sender.name }
          span(class: "message-content") { message.content }
        end
      end
    end
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
        Row gap: 8 do
          Input name: "message[content]", label: "Message", placeholder: "Type your message..."
          Button label: "Send", variant: :primary
        end
      end
      Row justify: "end" do
        Button label: "Close Conversation", variant: :ghost, tag: :a, href: new_conversation_closure_path(@conversation)
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
