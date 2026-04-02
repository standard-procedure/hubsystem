# frozen_string_literal: true

class Components::Grid < Components::Slotted
  COLORS = %i[bright primary muted dim phosphor amber alert cryo].freeze

  class Column < Literal::Data
    extend Components::Types

    prop :label, String
    prop :width, Integer, default: 1
  end

  class Cell < Literal::Data
    extend Components::Types

    prop :value, String
    prop :color, _Nilable(OneOf(COLORS)), default: nil
    prop :column_width, Integer, default: 1
  end

  class Row < Literal::Data
    prop :cells, _Array(Cell)
  end

  prop :columns, _Any
  prop :max_height, _Nilable(String), default: nil
  prop :scroll_to, OneOf(:last, :first), default: :last

  def initialize(...)
    @rows = []
    super
  end

  def row(*values)
    cells = values.each_with_index.map do |value, i|
      col_width = @columns[i]&.width || 1
      if value.is_a?(Hash)
        Cell.new(value: value[:value].to_s, color: value[:color], column_width: col_width)
      else
        Cell.new(value: value.to_s, column_width: col_width)
      end
    end
    @rows << Row.new(cells: cells)
  end

  def view_template
    style = "".dup
    style << "max-height: #{@max_height};" if @max_height
    attrs = {class: "grid-viewer"}
    attrs[:style] = style if style.present?
    attrs[:data_controller] = "scroll-anchor"
    attrs[:data_scroll_anchor_position_value] = @scroll_to.to_s

    div(**attrs) do
      render_header
      div(class: "grid-body") do
        @rows.each { |r| render_row(r) }
      end
    end
  end

  private

  def render_header
    div class: "grid-header" do
      @columns.each do |col|
        span(style: "flex: #{col.width}") { col.label }
      end
    end
  end

  def render_row(row)
    div class: "grid-row" do
      row.cells.each do |cell|
        css = ["grid-cell"]
        css << "grid-cell--#{cell.color}" if cell.color
        span(class: css.join(" "), style: "flex: #{cell.column_width}") { cell.value }
      end
    end
  end
end
