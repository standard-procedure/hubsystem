# frozen_string_literal: true

class Components::Input < Components::Base
  prop :name, String
  prop :type, String, default: "text"
  prop :placeholder, _String?, default: nil
  prop :error, _String?, default: nil
  prop :required, _Boolean, default: false
  prop :label, _String?, default: nil
  prop :value, _Any?, default: nil
  prop :attributes, Hash, :**, default: {}.freeze

  def view_template
    Column gap: 1 do
      div(class: "section-label") { label_text } if @label.present?

      input_attrs = {
        type: @type,
        name: @name,
        class: input_classes,
        placeholder: @placeholder,
        value: @value,
        **@attributes
      }.compact

      input(**input_attrs)

      div(class: "section-alert") { error_text } if @error.present?
    end
  end

  private def label_text = @required ? "\u25B2 #{@label}" : "\u25CF #{@label}"
  private def error_text = "\u25B2 #{@error}"

  private def input_classes
    classes = ["input-field"]
    classes << "input-field--required" if @required && !@error
    classes << "input-field--error" if @error
    classes.join(" ")
  end
end
