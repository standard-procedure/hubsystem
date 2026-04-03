module Naming
  extend ActiveSupport::Concern

  class_methods do
    def friendly_name = model_name.human
    alias_method :fn, :friendly_name

    def plural_name = model_name.human(count: 2)
    alias_method :pn, :plural_name

    def attribute_name(*) = human_attribute_name(*)
    alias_method :an, :attribute_name

    def enum_name(attribute, enum_value) = human_attribute_name("#{attribute}.#{enum_value}")
    alias_method :en, :enum_name
  end

  def friendly_name = self.class.friendly_name
  alias_method :fn, :friendly_name
  def plural_name = self.class.plural_name
  alias_method :pn, :plural_name
  def attribute_name(*) = self.class.attribute_name(*)
  alias_method :an, :attribute_name
  def enum_name(attribute) = self.class.enum_name(attribute, send(attribute.to_sym))
  alias_method :en, :enum_name
end
