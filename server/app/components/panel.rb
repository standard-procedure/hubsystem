# frozen_string_literal: true

class Components::Panel < Components::Base
  prop :title, _String?, default: nil
  prop :variant, OneOf(:default, :active, :warning, :alert), default: :default
  prop :controls, Integer, default: 3
  prop :attributes, Hash, :**, default: {}.freeze

  def view_template(&)
    div(**mix(class: ["panel", ("panel--#{@variant}" unless @variant == :default), @attributes.delete(:class)], **@attributees)) do
      render_header if @title
      div(class: "panel-body", &)
    end
  end

  private def render_header
    div class: "panel-header" do
      span(class: "panel-title") { @title }
      div class: "panel-controls" do
        @controls.times { div(class: "panel-control") }
      end
    end
  end
end
