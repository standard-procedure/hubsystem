# frozen_string_literal: true

class Views::Conversations::New < Views::Base
  include Phlex::Rails::Helpers::FormWith

  prop :user, User
  prop :users, _Any

  def view_template
    render Views::Layouts::Application.new(title: "HubSystem", user: @user, active_nav: :messages) do
      render Components::Panel.new(title: "New Conversation") do
        form_with url: conversations_path, method: :post do |form|
          Column gap: 12 do
            div do
              label(for: "conversation_recipient_id") { "Recipient" }
              form.select :recipient_id, @users.map { |u| [u.name, u.id] }, {}, id: "conversation_recipient_id", class: "input"
            end
            Input name: "conversation[subject]", label: "Subject", placeholder: "What's this about?", type: "text", required: true
            Row justify: "end" do
              Button label: "Send Request", variant: :primary
            end
          end
        end
      end
    end
  end
end
