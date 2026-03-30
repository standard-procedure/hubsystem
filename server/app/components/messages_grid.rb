# frozen_string_literal: true

class Components::MessagesGrid < Components::Base
  prop :user, User
  prop :conversation, Conversation

  def view_template
    Grid(
      columns: [
        Components::Grid::Column.new(label: "Time", width: 1),
        Components::Grid::Column.new(label: "From", width: 1),
        Components::Grid::Column.new(label: "Message", width: 4)
      ],
      max_height: "400px"
    ) do |grid|
      @conversation.messages.each do |message|
        sender_color = (message.sender == @user) ? :phosphor : :bright
        grid.row(
          {value: message.created_at.strftime("%H:%M"), color: :dim},
          {value: message.sender.name, color: sender_color},
          message.content
        )
      end
    end
  end
end
