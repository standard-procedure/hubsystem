# frozen_string_literal: true

class Components::InputField < Components::Base
  prop :name, String
  prop :type, String, default: "text"
  prop :placeholder, _String?, default: nil
  prop :error, _String?, default: nil
  prop :label, _String?, default: nil
  prop :attributes, Hash, :**, default: {}.freeze

  def view_template
    if @label
      div(class: "section-label") { @label }
    end

    input_attrs = {
      type: @type,
      name: @name,
      class: input_classes,
      placeholder: @placeholder,
      **@attributes
    }.compact

    input(**input_attrs)

    if @error
      div(class: "alert-banner alert-banner--critical", style: "margin-top: 4px; padding: 6px 12px;") do
        plain @error
      end
    end
  end

  private

  def input_classes
    classes = ["input-field"]
    classes << "input-field--error" if @error
    classes.join(" ")
  end
end
