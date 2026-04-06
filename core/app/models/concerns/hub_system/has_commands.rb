# frozen_string_literal: true

module HubSystem::HasCommands
  extend ActiveSupport::Concern

  class_methods do
    def command(name, async: false, &block)
      # Create a Literal::Struct subclass as the command class — param calls
      # forward to prop, giving us Literal's full type system for free
      command_class = Class.new(Literal::Struct)
      const_set(name.to_s.camelize, command_class)

      builder = HubSystem::CommandDefinition::Builder.new(name, async: async)
      capture = CallCapture.new(builder, command_class)
      capture.instance_exec(&block)

      # Extract the call method if defined in the block
      call_module = Module.new
      if capture.singleton_class.method_defined?(:call, false)
        captured_method = capture.singleton_class.instance_method(:call)
        call_module.define_method(:call) { |**args, &blk| captured_method.bind_call(capture, **args, &blk) }
      end

      definition = builder.build(call_module)

      # Register in catalogue
      commands[name] = definition

      # Add class-level metadata
      command_class.define_singleton_method(:description) { definition.description_text }
      command_class.define_singleton_method(:return_types) { definition.return_types }
      command_class.define_singleton_method(:exception_types) { definition.exception_types }
      command_class.define_singleton_method(:authorised?) { |actor| definition.authorisation_block.call(actor) }
      command_class.define_singleton_method(:command_definition) { definition }

      # Add instance method on the model
      model_key = self.name.underscore.to_sym
      define_method(name) do |actor:, **params, &blk|
        HubSystem::Command.call(command_class, definition: definition, actor: actor, **params.merge(model_key => self), &blk)
      end
    end

    def commands
      @_commands ||= {}
    end
  end

  # Evaluates the command block. Forwards:
  # - param → Literal::Struct.prop on the command class (full Literal type system)
  # - description, authorisation, returns, raises → Builder
  # - def call → captured as singleton method for extraction
  class CallCapture
    def initialize(builder, command_class)
      @builder = builder
      @command_class = command_class
    end

    def param(name, type, *rest, **opts)
      @command_class.prop(name, type, *rest, **opts)
    end

    def description(text) = @builder.description(text)
    def authorisation(&block) = @builder.authorisation(&block)
    def returns(*types) = @builder.returns(*types)
    def raises(*types) = @builder.raises(*types)
  end
end
