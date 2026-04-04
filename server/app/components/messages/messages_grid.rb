# frozen_string_literal: true

class Components::Messages::MessagesGrid < Components::Base
  prop :user, User
  prop :messages, ActiveRecord::Relation(Conversation::Message)
  prop :selected_message, _Nilable(Conversation::Message), default: nil
  prop :show_subject, _Boolean, default: true

  def view_template
    Grid(
      columns: grid_columns,
      max_height: "400px",
      scroll_to: @selected_message ? :selected : :last
    ) do |grid|
      @messages.each do |message|
        cells = build_cells(message)
        if @selected_message == message
          grid.row(*cells, id: dom_id(message, :grid_row)) { render Components::MarkdownViewer.new(content: message.contents) }
        else
          grid.row(*cells, id: dom_id(message, :grid_row))
        end
      end
    end
  end

  private

  def grid_columns
    [
      Components::Grid::Column.new(label: Conversation::Message.an(:created_at), width: 1),
      Components::Grid::Column.new(label: Conversation::Message.an(:sender), width: 1),
      (Components::Grid::Column.new(label: Conversation.an(:subject), width: 1) if @show_subject),
      Components::Grid::Column.new(label: Conversation::Message.an(:contents), width: 4)
    ].compact
  end

  def build_cells(message)
    color = row_color(message)
    [
      {value: l(message.created_at, format: :short), color: color, href: message_path(message)},
      {value: message.sender.to_s, color: color, href: message_path(message)},
      ({value: message.conversation.subject, color: color, href: message_path(message)} if @show_subject),
      {value: message.contents, color: color, href: message_path(message)}
    ].compact
  end

  def row_color(message)
    if message.sender == @user
      :dim
    elsif message.read_by?(@user)
      :muted
    else
      :phosphor
    end
  end
end
