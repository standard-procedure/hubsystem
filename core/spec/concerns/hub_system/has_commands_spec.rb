# frozen_string_literal: true

require "rails_helper"

RSpec.describe HubSystem::HasCommands do
  before(:all) do
    Widget.include HubSystem::HasCommands

    Widget.command :frobnicate do
      description "Frobnicate the widget"
      param :widget, Widget
      param :name, String
      returns Widget
      raises ArgumentError

      authorisation { |_user| true }

      def call(widget:, name:)
        widget.update!(name: name)
        widget
      end
    end

    Widget.command :restricted_action do
      description "A restricted action"
      param :widget, Widget
      # No authorisation block — should default to deny
      def call(widget:)
        widget
      end
    end
  end

  let(:user) { User.create!(name: "Alice") }
  let(:widget) { Widget.create!(name: "Original") }

  describe ".command macro" do
    it "registers the command in the catalogue" do
      expect(Widget.commands).to include(:frobnicate)
    end

    it "creates a constant on the model" do
      expect(defined?(Widget::Frobnicate)).to eq("constant")
    end
  end

  describe "command catalogue" do
    it "returns metadata for registered commands" do
      definition = Widget.commands[:frobnicate]
      expect(definition).to be_a(HubSystem::CommandDefinition)
      expect(definition.description_text).to eq("Frobnicate the widget")
      expect(definition.params).to eq({widget: Widget, name: String})
      expect(definition.return_types).to eq([Widget])
      expect(definition.exception_types).to eq([ArgumentError])
    end
  end

  describe "instance method" do
    it "calls the command via HubSystem::Command" do
      result = widget.frobnicate(actor: user, name: "Frobbed")
      expect(result).to eq(widget)
      expect(widget.reload.name).to eq("Frobbed")
    end

    it "creates a command log entry" do
      expect {
        widget.frobnicate(actor: user, name: "Logged")
      }.to change(HubSystem::CommandLogEntry, :count).by(1)

      entry = HubSystem::CommandLogEntry.last
      expect(entry.command_class).to eq("Widget::Frobnicate")
      expect(entry.actor).to eq(user)
      expect(entry).to be_completed
    end
  end

  describe "authorisation" do
    it "denies when no authorisation block is defined" do
      expect {
        widget.restricted_action(actor: user)
      }.to raise_error(HubSystem::Command::Unauthorised)
    end

    it "allows when authorisation returns true" do
      expect {
        widget.frobnicate(actor: user, name: "Allowed")
      }.not_to raise_error
    end
  end

  describe "failure handling" do
    before(:all) do
      Widget.command :exploding do
        param :widget, Widget
        authorisation { |_user| true }
        def call(widget:)
          raise "Boom!"
        end
      end
    end

    it "logs failed commands" do
      expect {
        widget.exploding(actor: user) rescue nil
      }.to change(HubSystem::CommandLogEntry, :count).by(1)

      entry = HubSystem::CommandLogEntry.last
      expect(entry).to be_failed
      expect(entry.error).to include("Boom!")
    end

    it "re-raises the exception" do
      expect {
        widget.exploding(actor: user)
      }.to raise_error(RuntimeError, "Boom!")
    end
  end
end
