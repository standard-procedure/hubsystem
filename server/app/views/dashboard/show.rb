# frozen_string_literal: true

class Views::Dashboard::Show < Views::Base
  prop :user, User
  prop :conversations, _Any, default: [].freeze

  def view_template
    render Views::Layouts::Application.new(title: "HubSystem", user: @user) do
      Components::SystemPanel(title: "Welcome back #{@user}", subtitle: "Human \u2194 Agent Interface Protocol") do
        Terminal do |terminal|
          terminal.bright_line { "HUBSYSTEM INTERFACE TERMINAL v1.0" }
          terminal.line { "MU/TH/UR 6000 BIOS rev 4.2.1" }
          terminal.line { "#{@conversations.count} active conversation(s)" }
          terminal.bright_line do
            plain "SYSTEM READY"
            span(class: "cursor")
          end
        end
      end

      render Components::Panel.new(title: "Conversations") do
        StatusMatrix do |matrix|
          @conversations.each do |conversation|
            matrix.item state: conversation_state(conversation), href: conversation_path(conversation)
          end
        end
      end
    end
  end

  private

  def conversation_state(conversation)
    if conversation.requested? && conversation.recipient == @user
      :critical
    elsif conversation.closed?
      :offline
    elsif conversation.has_unread_messages_for?(@user)
      :warning
    else
      :nominal
    end
  end
end
