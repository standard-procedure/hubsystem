module ConversationSteps
  step "I have logged in as Alice" do
    OmniAuth.config.add_mock :developer, uid: "alice-google-123"
    visit root_path
    click_on "Developer login"
  end

  step "I ask Bob to start a conversation" do
    click_on "Users"
    click_on "Bob"
    click_on "Start conversation"
    fill_in "Subject", with: "Hi Bob"
    click_on "Send"
  end
end
