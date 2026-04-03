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
        if @selected_message && message.id == @selected_message.id
          grid.row(*cells, id: dom_id(message, :grid_row)) do
            render Components::MarkdownViewer.new(content: message.contents)
          end
        else
          grid.row(*cells, id: dom_id(message, :grid_row))
        end
      end
    end
  end

  private

  def grid_columns
    cols = [
      Components::Grid::Column.new(label: Conversation::Message.an(:created_at), width: 1),
      Components::Grid::Column.new(label: Conversation::Message.an(:sender), width: 1)
    ]
    cols << Components::Grid::Column.new(label: Conversation.an(:subject), width: 1) if @show_subject
    cols << Components::Grid::Column.new(label: Conversation::Message.an(:contents), width: 4)
    cols
  end

  def build_cells(message)
    cells = [
      {value: l(message.created_at, format: :short), color: (message.read_by?(@user) ? :dim : :phosphor), href: message_path(message)},
      {value: message.sender.to_s, href: message_path(message)}
    ]
    cells << {value: message.conversation.subject, href: message_path(message)} if @show_subject
    cells << {value: message.contents, href: message_path(message)}
    cells
  end
end
