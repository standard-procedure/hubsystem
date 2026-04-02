# frozen_string_literal: true

class Components::Panel < Components::Base
  prop :title, _String?, default: nil
  prop :variant, OneOf(:default, :active, :warning, :alert), default: :default
  prop :controls, Integer, default: 3

  def view_template(&)
    div class: panel_classes do
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

  private def panel_classes
    classes = ["panel"]
    classes << "panel--#{@variant}" unless @variant == :default
    classes.join(" ")
  end
end
