# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Grid, type: :component do
  def controller
    @controller ||= ActionView::TestCase::TestController.new
  end

  def view_context
    controller.view_context
  end

  def render(component, &block)
    view_context.render(component, &block)
  end

  def render_fragment(component, &block)
    Nokogiri::HTML5.fragment(render(component, &block))
  end

  let(:columns) do
    [
      Components::Grid::Column.new(label: "Name", width: 2),
      Components::Grid::Column.new(label: "Value", width: 1)
    ]
  end

  describe "header" do
    it "renders column labels" do
      html = render_fragment(described_class.new(columns: columns)) do |grid|
        grid.row({value: "Alice"}, {value: "100"})
      end

      labels = html.css(".grid-header span").map(&:text)
      expect(labels).to eq(["Name", "Value"])
    end
  end

  describe "#row" do
    it "renders a grid-row for each row" do
      html = render_fragment(described_class.new(columns: columns)) do |grid|
        grid.row({value: "Alice"}, {value: "100"})
        grid.row({value: "Bob"}, {value: "200"})
      end

      expect(html.css(".grid-row").length).to eq(2)
    end

    it "renders cell values" do
      html = render_fragment(described_class.new(columns: columns)) do |grid|
        grid.row({value: "Alice"}, {value: "100"})
      end

      cells = html.css(".grid-cell").map(&:text)
      expect(cells).to eq(["Alice", "100"])
    end

    it "renders cells as links when href is provided" do
      html = render_fragment(described_class.new(columns: columns)) do |grid|
        grid.row({value: "Alice", href: "/alice"}, {value: "100"})
      end

      link = html.at_css("a.grid-cell")
      expect(link["href"]).to eq("/alice")
      expect(link.text).to eq("Alice")
    end

    it "sets the HTML id when id: is provided" do
      html = render_fragment(described_class.new(columns: columns)) do |grid|
        grid.row({value: "Alice"}, {value: "100"}, id: "row-1")
      end

      row = html.at_css(".grid-row")
      expect(row["id"]).to eq("row-1")
    end

    it "does not set an id when id: is nil" do
      html = render_fragment(described_class.new(columns: columns)) do |grid|
        grid.row({value: "Alice"}, {value: "100"})
      end

      row = html.at_css(".grid-row")
      expect(row["id"]).to be_nil
    end
  end

  describe "expanded rows" do
    it "renders expanded content when a block is given" do
      html = render_fragment(described_class.new(columns: columns)) do |grid|
        grid.row({value: "Alice"}, {value: "100"}) do
          "Expanded content here"
        end
      end

      expanded = html.at_css(".grid-row-expanded")
      expect(expanded).to be_present
      expect(expanded.text).to include("Expanded content here")
    end

    it "does not render expanded content for rows without a block" do
      html = render_fragment(described_class.new(columns: columns)) do |grid|
        grid.row({value: "Alice"}, {value: "100"})
      end

      expect(html.at_css(".grid-row-expanded")).to be_nil
    end

    it "marks expanded rows with data-scroll-anchor-target" do
      html = render_fragment(described_class.new(columns: columns)) do |grid|
        grid.row({value: "Alice"}, {value: "100"}) do
          "Expanded"
        end
      end

      row = html.at_css(".grid-row")
      expect(row["data-scroll-anchor-target"]).to eq("selected")
    end

    it "does not mark non-expanded rows with data-scroll-anchor-target" do
      html = render_fragment(described_class.new(columns: columns)) do |grid|
        grid.row({value: "Alice"}, {value: "100"})
      end

      row = html.at_css(".grid-row")
      expect(row["data-scroll-anchor-target"]).to be_nil
    end
  end

  describe "scroll_to" do
    it "defaults to last" do
      html = render_fragment(described_class.new(columns: columns)) do |grid|
        grid.row({value: "Alice"}, {value: "100"})
      end

      container = html.children.first
      expect(container["data-scroll-anchor-position-value"]).to eq("last")
    end

    it "accepts :selected" do
      html = render_fragment(described_class.new(columns: columns, scroll_to: :selected)) do |grid|
        grid.row({value: "Alice"}, {value: "100"})
      end

      container = html.children.first
      expect(container["data-scroll-anchor-position-value"]).to eq("selected")
    end
  end
end
