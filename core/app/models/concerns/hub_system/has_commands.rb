# frozen_string_literal: true

module HubSystem::HasCommands
  extend ActiveSupport::Concern

  class_methods do
    def command(name, &block)
      builder = HubSystem::CommandDefinition::Builder.new(name)

      # Evaluate the block in a context that captures both DSL declarations
      # and the def call method definition
      capture = CallCapture.new(builder)
      capture.instance_exec(&block)

      # Extract the call method as an UnboundMethod if it was defined
      call_module = Module.new
      if capture.singleton_class.method_defined?(:call, false)
        captured_method = capture.singleton_class.instance_method(:call)
        call_module.define_method(:call) { |**args| captured_method.bind_call(capture, **args) }
      end

      definition = builder.build(call_module)

      # Register in catalogue
      commands[name] = definition

      # Create a command class constant
      command_class = Class.new
      const_set(name.to_s.camelize, command_class)

      # Add class-level metadata
      command_class.define_singleton_method(:description) { definition.description_text }
      command_class.define_singleton_method(:params_metadata) { definition.params }
      command_class.define_singleton_method(:return_types) { definition.return_types }
      command_class.define_singleton_method(:exception_types) { definition.exception_types }
      command_class.define_singleton_method(:authorised?) { |actor| definition.authorisation_block.call(actor) }

      # Add instance method on the model
      model_key = self.name.underscore.to_sym
      define_method(name) do |actor:, **params|
        HubSystem::Command.call(command_class, definition: definition, actor: actor, **params.merge(model_key => self))
      end
    end

    def commands
      @_commands ||= {}
    end
  end

  # Evaluates the command block, forwarding DSL methods to the builder.
  # Any `def call` defined inside instance_exec becomes a singleton method
  # on this object, which the macro then extracts.
  class CallCapture
    def initialize(builder)
      @builder = builder
    end

    def param(name, type) = @builder.param(name, type)
    def description(text) = @builder.description(text)
    def authorisation(&block) = @builder.authorisation(&block)
    def returns(*types) = @builder.returns(*types)
    def raises(*types) = @builder.raises(*types)
  end
end
