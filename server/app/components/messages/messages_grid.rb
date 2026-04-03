# frozen_string_literal: true

class Components::Messages::MessagesGrid < Components::Base
  prop :user, User
  prop :messages, ActiveRecord::Relation(Conversation::Message)

  def view_template
    Grid(
      columns: [
        Components::Grid::Column.new(label: Conversation::Message.an(:created_at), width: 1),
        Components::Grid::Column.new(label: Conversation::Message.an(:sender), width: 1),
        Components::Grid::Column.new(label: Conversation.an(:subject), width: 1),
        Components::Grid::Column.new(label: Conversation::Message.an(:contents), width: 4)
      ],
      max_height: "400px"
    ) do |grid|
      @messages.each do |message|
        grid.row(
          {value: l(message.created_at, format: :short), color: (message.read_by?(@user) ? :dim : :phosphor), href: message_path(message)},
          {value: message.sender.to_s, href: message_path(message)},
          {value: message.conversation.subject, href: message_path(message)},
          {value: message.contents, href: message_path(message)}
        )
      end
    end
  end
end
