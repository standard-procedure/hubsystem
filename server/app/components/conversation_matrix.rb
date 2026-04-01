# frozen_string_literal: true

class Components::ConversationMatrix < Components::Base
  include Phlex::Rails::Helpers::TurboStreamFrom

  prop :user, User
  prop :conversations, ActiveRecord::Relation(Conversation), default: [].freeze

  def view_template
    div id: "conversation_matrix" do
      turbo_stream_from(@user, :conversation_matrix)
      StatusMatrix do |matrix|
        @conversations.each do |conversation|
          matrix.item href: conversation_path(conversation)
        end
      end
    end
  end
end
