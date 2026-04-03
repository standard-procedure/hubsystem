# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Panel, type: :component do
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

  describe "panel structure" do
    it "renders a panel with a body" do
      html = render_fragment(described_class.new) { "Content" }

      expect(html.at_css(".panel")).to be_present
      expect(html.at_css(".panel-body").text).to eq("Content")
    end

    it "does not render a header when no title is given" do
      html = render_fragment(described_class.new) { "Content" }

      expect(html.at_css(".panel-header")).to be_nil
    end
  end

  describe "header" do
    it "renders a header with a title" do
      html = render_fragment(described_class.new(title: "Info")) { "Content" }

      expect(html.at_css(".panel-header")).to be_present
      expect(html.at_css(".panel-title").text).to eq("Info")
      expect(html.at_css(".panel-title").name).to eq("span")
    end

    it "renders the title as a link when href is provided" do
      html = render_fragment(described_class.new(title: "Info", href: "/info")) { "Content" }

      link = html.at_css("a.panel-title")
      expect(link).to be_present
      expect(link["href"]).to eq("/info")
      expect(link.text).to eq("Info")
    end

    it "renders the title as a span when href is not provided" do
      html = render_fragment(described_class.new(title: "Info")) { "Content" }

      title = html.at_css(".panel-title")
      expect(title.name).to eq("span")
    end

    it "renders control placeholders" do
      html = render_fragment(described_class.new(title: "Info", controls: 2)) { "Content" }

      expect(html.css(".panel-control").length).to eq(2)
    end

    it "renders 3 controls by default" do
      html = render_fragment(described_class.new(title: "Info")) { "Content" }

      expect(html.css(".panel-control").length).to eq(3)
    end
  end

  describe "variants" do
    it "does not add a variant class for the default variant" do
      html = render_fragment(described_class.new) { "Content" }

      panel = html.at_css(".panel")
      expect(panel["class"]).to eq("panel")
    end

    it "adds a variant class for non-default variants" do
      html = render_fragment(described_class.new(variant: :active)) { "Content" }

      expect(html.at_css(".panel.panel--active")).to be_present
    end
  end
end
