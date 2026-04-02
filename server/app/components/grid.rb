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
    prop :href, _String?
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
        Cell.new(value: value[:value].to_s, color: value[:color], href: value[:href], column_width: col_width)
      else
        Cell.new(value: value.to_s, href: value[:href], column_width: col_width)
      end
    end
    @rows << Row.new(cells: cells)
  end

  def view_template
    div(style: {max_height: @max_height}, data: {controller: "scroll-anchor", scroll_anchor_position_value: @scroll_to.to_s}) do
      render_header
      div(class: %w[grid-body]) do
        @rows.each { |r| render_row(r) }
      end
    end
  end

  private def render_header
    div class: "grid-header" do
      @columns.each do |col|
        span(style: "flex: #{col.width}") { col.label }
      end
    end
  end

  private def render_row(row)
    div class: "grid-row" do
      row.cells.each do |cell|
        cell.href.blank? ? draw(cell) : draw_link_for(cell)
      end
    end
  end

  private def draw(cell) = span(class: css_for(cell), style: {flex: cell.column_width}) { cell.value }
  private def draw_link_for(cell) = a(href: cell.href, class: css_for(cell), style: {flex: cell.column_width}) { cell.value }
  private def css_for(cell) = ["grid-cell", ("grid-cell--#{cell.color}" if cell.color)]
end
