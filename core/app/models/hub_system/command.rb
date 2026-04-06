# frozen_string_literal: true

require "async"

module HubSystem::Command
  Unauthorised = Class.new(StandardError)

  def self.call(command_class, definition:, actor:, **params, &blk)
    raise Unauthorised, "Not authorised to run #{command_class.name}" unless definition.authorisation_block.call(actor)

    definition.async ? call_async(command_class, definition, actor, **params, &blk) : call_sync(command_class, definition, actor, **params, &blk)
  end

  def self.call_sync(command_class, definition, actor, **params, &blk)
    entry, resolved_params = prepare(command_class, actor, **params)
    executor = build_executor(definition)
    result = executor.call(**resolved_params, &blk)
    entry.update!(status: :completed, result: result.to_s)
    result
  rescue Unauthorised
    raise
  rescue => error
    entry&.update!(status: :failed, error: "#{error.class}: #{error.message}")
    raise
  end

  def self.call_async(command_class, definition, actor, **params, &blk)
    Async do
      call_sync(command_class, definition, actor, **params, &blk)
    end
  end

  def self.prepare(command_class, actor, **params)
    instance = command_class.new(**params)
    resolved_params = command_class.literal_properties
      .select(&:keyword?)
      .to_h { |p| [p.name, instance.public_send(p.name)] }

    entry = HubSystem::CommandLogEntry.create!(
      command_class: command_class.name,
      actor: actor,
      params: serialise_params(resolved_params),
      status: :started
    )

    [entry, resolved_params]
  end

  def self.build_executor(definition)
    executor = Object.new
    executor.extend(definition.call_module)
    executor
  end

  def self.serialise_params(params)
    params.transform_values do |v|
      v.respond_to?(:id) ? {class: v.class.name, id: v.id} : v
    end
  end
end
