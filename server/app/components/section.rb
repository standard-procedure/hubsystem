# frozen_string_literal: true

class Components::Section < Components::Base
  prop :label, _String?, default: nil
  prop :title, String
  prop :description, _String?, default: nil

  def view_template(&)
    div class: "section" do
      div(class: "section-label") { @label } if @label
      div(class: "section-title") { @title }
      div(class: "section-desc") { @description } if @description
      yield if block_given?
    end
  end
end
