# frozen_string_literal: true

class Views::UserConversations::New < Views::Base
  prop :recipient, User
  prop :conversation, _Nilable(Conversation), default: nil

  def view_template
    render Views::Layouts::Application.new(title: "HubSystem", user: Current.user, active_nav: :messages) do
      render Components::Panel.new(title: "Start Conversation with #{@recipient.name}") do
        form action: user_conversations_path(@recipient), method: :post do
          input type: "hidden", name: "authenticity_token", value: form_authenticity_token
          Column gap: 4 do
            Input name: "conversation[subject]", label: "Subject", required: true,
              value: @conversation&.subject,
              error: @conversation&.errors&.[](:subject)&.first
            Row justify: "end", gap: 2 do
              Button label: "Cancel", variant: :secondary, tag: :a, href: user_path(@recipient)
              Button label: "Send Request", variant: :primary
            end
          end
        end
      end
    end
  end
end
