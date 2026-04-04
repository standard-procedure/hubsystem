# frozen_string_literal: true

module ManagingConversationSteps
  extend Turnip::DSL

  step "I have an active conversation" do
    @conversation = conversations(:alpha)
  end
end
