# frozen_string_literal: true

class HubSystem::CommandDefinition < Literal::Data
  prop :name, Symbol, reader: :public
  prop :description_text, _String?, reader: :public, default: nil
  prop :authorisation_block, Proc, reader: :public, default: -> { ->(_user) { false } }
  prop :return_types, Array, reader: :public, default: [].freeze
  prop :exception_types, Array, reader: :public, default: [].freeze
  prop :call_module, Module, reader: :public

  class Builder
    def initialize(name)
      @name = name
      @authorisation_block = ->(_user) { false }
      @return_types = []
      @exception_types = []
      @description_text = nil
    end

    def description(text) = @description_text = text
    def authorisation(&block) = @authorisation_block = block
    def returns(*types) = @return_types = types.flatten
    def raises(*types) = @exception_types = types.flatten

    def build(call_module)
      HubSystem::CommandDefinition.new(
        name: @name,
        description_text: @description_text,
        authorisation_block: @authorisation_block,
        return_types: @return_types,
        exception_types: @exception_types,
        call_module: call_module
      )
    end
  end
end
