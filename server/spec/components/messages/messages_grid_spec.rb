# frozen_string_literal: true

require "rails_helper"

RSpec.describe Components::Messages::MessagesGrid, type: :component do
  fixtures :users, :conversations, :conversation_participants, :conversation_messages, :conversation_message_readings

  def controller
    @controller ||= ActionView::TestCase::TestController.new
  end

  def view_context
    controller.view_context
  end

  def render(component, &block)
    view_context.render(component, &block)
  end

  def render_fragment(component, &block)
    Nokogiri::HTML5.fragment(render(component, &block))
  end

  let(:user) { users(:alice) }
  let(:messages) { conversations(:alpha).messages }

  describe "columns" do
    it "renders the subject column by default" do
      html = render_fragment(described_class.new(user: user, messages: messages))
      headers = html.css(".grid-header span").map(&:text)
      expect(headers).to include(Conversation.an(:subject))
    end

    it "omits the subject column when show_subject is false" do
      html = render_fragment(described_class.new(user: user, messages: messages, show_subject: false))
      headers = html.css(".grid-header span").map(&:text)
      expect(headers).not_to include(Conversation.an(:subject))
    end
  end

  describe "row IDs" do
    it "sets dom_id on each row" do
      html = render_fragment(described_class.new(user: user, messages: messages))
      messages.each do |message|
        expect(html.at_css("#grid_row_conversation_message_#{message.id}")).to be_present
      end
    end
  end

  describe "selected_message" do
    it "renders expanded content for the selected message" do
      selected = conversation_messages(:alice_hello)
      html = render_fragment(described_class.new(user: user, messages: messages, selected_message: selected))
      expanded_row = html.at_css("#grid_row_conversation_message_#{selected.id}")
      expect(expanded_row.at_css(".grid-row-expanded")).to be_present
      expect(expanded_row.at_css(".markdown-viewer")).to be_present
    end

    it "does not render expanded content for other messages" do
      selected = conversation_messages(:alice_hello)
      other = conversation_messages(:bob_reply)
      html = render_fragment(described_class.new(user: user, messages: messages, selected_message: selected))
      other_row = html.at_css("#grid_row_conversation_message_#{other.id}")
      expect(other_row.at_css(".grid-row-expanded")).to be_nil
    end

    it "does not render expanded content when no message is selected" do
      html = render_fragment(described_class.new(user: user, messages: messages))
      expect(html.at_css(".grid-row-expanded")).to be_nil
    end
  end
end
