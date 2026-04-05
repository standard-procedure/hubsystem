# frozen_string_literal: true

module HubSystem::Command
  Unauthorised = Class.new(StandardError)

  def self.call(command_class, definition:, actor:, **params)
    raise Unauthorised, "Not authorised to run #{command_class.name}" unless definition.authorisation_block.call(actor)

    entry = HubSystem::CommandLogEntry.create!(
      command_class: command_class.name,
      actor: actor,
      params: serialise_params(params),
      status: :started
    )

    instance = command_class.new
    instance.extend(definition.call_module)
    result = instance.call(**params)
    entry.update!(status: :completed, result: result.to_s)
    result
  rescue Unauthorised
    raise
  rescue => error
    entry&.update!(status: :failed, error: "#{error.class}: #{error.message}")
    raise
  end

  def self.serialise_params(params)
    params.transform_values do |v|
      v.respond_to?(:id) ? {class: v.class.name, id: v.id} : v
    end
  end
end
