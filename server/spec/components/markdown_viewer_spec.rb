# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::MarkdownViewer, type: :component do
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

  describe "rendering markdown" do
    it "renders plain text as a paragraph" do
      html = render_fragment(described_class.new(content: "Hello world"))
      expect(html.at_css("article.markdown-viewer p").text).to eq("Hello world")
    end

    it "converts line breaks with hard_wrap" do
      html = render_fragment(described_class.new(content: "Line one\nLine two"))
      brs = html.css("article.markdown-viewer br")
      expect(brs.length).to be >= 1
    end

    it "renders fenced code blocks" do
      content = "```ruby\nputs 'hello'\n```"
      html = render_fragment(described_class.new(content: content))
      expect(html.at_css("article.markdown-viewer code").text.strip).to eq("puts 'hello'")
    end

    it "escapes raw HTML input" do
      html = render_fragment(described_class.new(content: "<script>alert('xss')</script>"))
      expect(html.at_css("script")).to be_nil
      expect(html.to_s).to include("&lt;script&gt;")
    end
  end

  describe "attributes" do
    it "renders with the markdown-viewer class by default" do
      html = render_fragment(described_class.new(content: "test"))
      expect(html.at_css("article.markdown-viewer")).to be_present
    end

    it "merges extra attributes via mix" do
      html = render_fragment(described_class.new(content: "test", id: "my-viewer", data: {foo: "bar"}))
      article = html.at_css("article.markdown-viewer")
      expect(article["id"]).to eq("my-viewer")
      expect(article["data-foo"]).to eq("bar")
    end

    it "merges extra classes" do
      html = render_fragment(described_class.new(content: "test", class: "extra"))
      article = html.at_css("article")
      expect(article["class"]).to include("markdown-viewer")
      expect(article["class"]).to include("extra")
    end
  end
end
