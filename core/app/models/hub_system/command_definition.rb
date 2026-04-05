# frozen_string_literal: true

class HubSystem::CommandDefinition < Literal::Object
  prop :name, Symbol, reader: :public
  prop :params, Hash, reader: :public, default: {}.freeze
  prop :description_text, _String?, reader: :public, default: nil
  prop :authorisation_block, Proc, reader: :public, default: -> { ->(_user) { false } }
  prop :return_types, Array, reader: :public, default: [].freeze
  prop :exception_types, Array, reader: :public, default: [].freeze
  prop :call_module, Module, reader: :public

  class Builder
    def initialize(name)
      @name = name
      @params = {}
      @authorisation_block = ->(_user) { false }
      @return_types = []
      @exception_types = []
      @description_text = nil
    end

    def param(name, type) = @params[name] = type
    def description(text) = @description_text = text
    def authorisation(&block) = @authorisation_block = block
    def returns(*types) = @return_types = types
    def raises(*types) = @exception_types = types

    def build(call_module)
      HubSystem::CommandDefinition.new(
        name: @name,
        params: @params.freeze,
        description_text: @description_text,
        authorisation_block: @authorisation_block,
        return_types: @return_types.freeze,
        exception_types: @exception_types.freeze,
        call_module: call_module
      )
    end
  end
end
