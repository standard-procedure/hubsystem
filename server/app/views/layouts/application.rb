# frozen_string_literal: true

class Views::Layouts::Application < Views::Base
  include Phlex::Rails::Helpers::CSRFMetaTags
  include Phlex::Rails::Helpers::CSPMetaTag
  include Phlex::Rails::Helpers::StylesheetLinkTag
  include Phlex::Rails::Helpers::JavascriptIncludeTag
  include Phlex::Rails::Helpers::T
  include Phlex::Rails::Helpers::ClassNames
  include Phlex::Rails::Helpers::ImageTag

  prop :title, String
  prop :subtitle, String, default: ""
  prop :lang, String, default: "en"
  prop :head, _Callable?
  prop :attributes, Hash, :**, default: {}.freeze

  def view_template(&)
    doctype
    html(lang: @lang) do
      head { render_head }
      body do
        render Components::CrtMonitor.new(brand: @title), &
      end
    end
  end

  private def render_head
    title { @title }
    csrf_meta_tags
    csp_meta_tag
    meta name: "viewport", content: "width=device-width,initial-scale=1,user-scalable=no"
    meta name: "apple-mobile-web-app-capable", content: "yes"
    meta name: "mobile-web-app-capable", content: "yes"
    meta name: "turbo-refresh-method", content: "morph"
    meta name: "turbo-refresh-scroll", content: "preserve"
    meta name: "view-transition", content: "same-origin"
    stylesheet_link_tag :app, "data-turbo-track": "reload"
    javascript_include_tag "application", "data-turbo-track": "reload", type: "module"
    link rel: "icon", href: "/icon.png", type: "image/png"
    link rel: "icon", href: "/icon.svg", type: "image/svg+xml"
    link rel: "apple-touch-icon", href: "/icon.png"
    @head&.call
  end
end
