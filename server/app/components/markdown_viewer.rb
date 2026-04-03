# frozen_string_literal: true

class Components::MarkdownViewer < Components::Base
  RENDERER = Redcarpet::Markdown.new(
    Redcarpet::Render::HTML.new(escape_html: true, hard_wrap: true),
    fenced_code_blocks: true,
    no_intra_emphasis: true
  )

  prop :content, String
  prop :attributes, Hash, :**, default: {}.freeze

  def view_template
    article(**mix(class: ["markdown-viewer", @attributes.delete(:class)], **@attributes)) do
      raw safe(RENDERER.render(@content))
    end
  end
end
