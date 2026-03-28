# frozen_string_literal: true

class Views::ConversationClosures::New < Views::Base
  include Phlex::Rails::Helpers::FormWith

  prop :user, User
  prop :conversation, Conversation

  def view_template
    render Views::Layouts::Application.new(title: "HubSystem", user: @user, active_nav: :messages) do
      render Components::Panel.new(title: "Close Conversation") do
        p { "Are you sure you want to close \"#{@conversation.subject}\" with #{@conversation.other_participant(@user).name}?" }
        Row gap: 8, justify: "end" do
          Button label: "Cancel", variant: :ghost, tag: :a, href: conversation_path(@conversation)
          form_with url: conversation_closure_path(@conversation), method: :post do
            Button label: "Close Conversation", variant: :danger
          end
        end
      end
    end
  end
end
