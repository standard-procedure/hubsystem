# frozen_string_literal: true

class Components::ConversationMatrix < Components::Base
  include Phlex::Rails::Helpers::TurboStreamFrom

  prop :user, User
  prop :conversations, _Any, default: [].freeze

  def view_template
    div id: "conversation_matrix" do
      turbo_stream_from(@user, :conversation_matrix) if respond_to?(:turbo_stream_from)
      StatusMatrix do |matrix|
        @conversations.each do |conversation|
          matrix.item state: conversation_state(conversation), href: conversation_path(conversation)
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
