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
              p(class: "field-label") { "Choose recipient" }
              div class: "radio-group" do
                @users.each do |u|
                  input type: "radio", name: "conversation[recipient_id]", value: u.id, id: "recipient_#{u.id}", required: true
                  label(for: "recipient_#{u.id}") { u.name }
                end
              end
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
