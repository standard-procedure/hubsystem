# frozen_string_literal: true

class Components::ConversationsGrid < Components::Base
  prop :user, User
  prop :conversations, ActiveRecord::Relation(Conversation)

  def view_template
    Grid(
      columns: [
        Components::Grid::Column.new(label: t(".subject"), width: 2),
        Components::Grid::Column.new(label: t(".participants"), width: 1)
      ],
      max_height: "400px"
    ) do |grid|
      @conversations.each do |conversation|
        grid.row(
          {value: conversation.subject, color: (conversation.has_unread_messages_for?(@user) ? :phosphor : :dim), href: conversation_path(conversation)},
          {value: conversation.participants.map(&:to_s).join(", "), href: conversation_path(conversation)}
        )
      end
    end
  end
end
