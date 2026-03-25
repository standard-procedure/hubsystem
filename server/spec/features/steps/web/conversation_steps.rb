module ConversationSteps
  step "I have logged in as Alice" do
    OmniAuth.config.add_mock :developer, uid: "alice-google-123"
    visit root_path
    click_on "Developer login"
  end
end
