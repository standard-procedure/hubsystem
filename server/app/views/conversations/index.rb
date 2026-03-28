# frozen_string_literal: true

class Views::Conversations::Index < Views::Base
  prop :user, User
  prop :conversations, _Any
  prop :archived, _Boolean, default: false

  def view_template
    render Views::Layouts::Application.new(title: "HubSystem", user: @user, active_nav: :messages) do
      render Components::Panel.new(title: "Conversations") do
        Navigation do |nav|
          nav.item label: "Active", active: !@archived, href: conversations_path
          nav.item label: "Archived", active: @archived, href: conversations_path(archived: true)
        end

        div class: "conversation-list" do
          if @conversations.any?
            @conversations.each { |conversation| render_conversation(conversation) }
          else
            p(class: "text-muted") { @archived ? "No archived conversations." : "No active conversations." }
          end
        end

        Row justify: "end" do
          Button label: "New Conversation", variant: :primary, tag: :a, href: new_conversation_path
        end
      end
    end
  end

  private

  def render_conversation(conversation)
    css = ["conversation-item"]
    css << "conversation-item--request" if conversation.requested? && conversation.recipient == @user
    css << "conversation-item--unread" if conversation.has_unread_messages_for?(@user)

    a href: conversation_path(conversation), class: css.join(" ") do
      span(class: "conversation-subject") { conversation.subject }
      span(class: "conversation-participant") { conversation.other_participant(@user).name }
      span(class: "conversation-status") { conversation_status_label(conversation) }
    end
  end

  def conversation_status_label(conversation)
    if conversation.requested? && conversation.recipient == @user
      "Pending request"
    elsif conversation.requested?
      "Awaiting response"
    elsif conversation.closed?
      "Closed"
    elsif conversation.has_unread_messages_for?(@user)
      "Unread"
    else
      "Active"
    end
  end
end
