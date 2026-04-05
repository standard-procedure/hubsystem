# frozen_string_literal: true

require "rails_helper"

RSpec.describe HubSystem::CommandDefinition do
  let(:call_module) do
    Module.new do
      def call(widget:, name:)
        widget.update!(name: name)
      end
    end
  end

  describe "properties" do
    it "stores the command name" do
      definition = described_class.new(name: :frobnicate, call_module: call_module)
      expect(definition.name).to eq(:frobnicate)
    end

    it "stores params" do
      definition = described_class.new(name: :frobnicate, params: {widget: Widget, name: String}, call_module: call_module)
      expect(definition.params).to eq({widget: Widget, name: String})
    end

    it "stores description" do
      definition = described_class.new(name: :frobnicate, description_text: "Do the thing", call_module: call_module)
      expect(definition.description_text).to eq("Do the thing")
    end

    it "stores return types" do
      definition = described_class.new(name: :frobnicate, return_types: [Widget], call_module: call_module)
      expect(definition.return_types).to eq([Widget])
    end

    it "stores exception types" do
      definition = described_class.new(name: :frobnicate, exception_types: [ArgumentError], call_module: call_module)
      expect(definition.exception_types).to eq([ArgumentError])
    end
  end

  describe "authorisation" do
    it "defaults to denying all" do
      definition = described_class.new(name: :frobnicate, call_module: call_module)
      expect(definition.authorisation_block.call(Object.new)).to be false
    end

    it "stores a custom authorisation block" do
      definition = described_class.new(name: :frobnicate, authorisation_block: ->(_user) { true }, call_module: call_module)
      expect(definition.authorisation_block.call(Object.new)).to be true
    end
  end
end

RSpec.describe HubSystem::CommandDefinition::Builder do
  it "captures params" do
    builder = described_class.new(:frobnicate)
    builder.param :widget, Widget
    builder.param :name, String

    call_mod = Module.new { def call(**); end }
    definition = builder.build(call_mod)

    expect(definition.params).to eq({widget: Widget, name: String})
  end

  it "captures description" do
    builder = described_class.new(:frobnicate)
    builder.description "Do the thing"

    call_mod = Module.new { def call(**); end }
    definition = builder.build(call_mod)

    expect(definition.description_text).to eq("Do the thing")
  end

  it "captures authorisation" do
    builder = described_class.new(:frobnicate)
    builder.authorisation { |_user| true }

    call_mod = Module.new { def call(**); end }
    definition = builder.build(call_mod)

    expect(definition.authorisation_block.call(nil)).to be true
  end

  it "captures returns and raises" do
    builder = described_class.new(:frobnicate)
    builder.returns Widget
    builder.raises ArgumentError

    call_mod = Module.new { def call(**); end }
    definition = builder.build(call_mod)

    expect(definition.return_types).to eq([Widget])
    expect(definition.exception_types).to eq([ArgumentError])
  end

  it "defaults authorisation to deny" do
    builder = described_class.new(:frobnicate)

    call_mod = Module.new { def call(**); end }
    definition = builder.build(call_mod)

    expect(definition.authorisation_block.call(nil)).to be false
  end
end
