# frozen_string_literal: true

module WebManagingConversationSteps
  extend Turnip::DSL

  step "I am logged in" do
    @user = users(:alice)
    @target_user = users(:dave)
    @new_subject = "Hello Dave"
    @new_message = "How are you doing?"
    @reply_message = "This is a new reply"
    OmniAuth.config.mock_auth[:developer] = OmniAuth::AuthHash.new(
      provider: "developer",
      uid: @user.identities.first.uid,
      info: {name: @user.name}
    )
    visit root_path
    click_button "Developer login"
  end

  step "I start a new conversation" do
    click_link "Messages"
    click_link "Conversations"
    click_link "New Conversation"
  end

  step "I search for a user" do
    fill_in "q", with: @target_user.name
    click_button "Find"
  end

  step "I select a user to talk to" do
    click_link @target_user.name
  end

  step "I fill in the subject and message" do
    fill_in "conversation[subject]", with: @new_subject
    fill_in "conversation[message]", with: @new_message
  end

  step "I send the conversation" do
    click_button "Start Conversation"
  end

  step "I should see the new conversation with my message" do
    expect(page).to have_content(@new_subject)
    expect(page).to have_content(@new_message)
  end

  step "I view the conversation" do
    click_link "Messages"
    click_link "Conversations"
    click_link @conversation.subject
  end

  step "I send a message" do
    fill_in "conversation_message[contents]", with: @reply_message
    click_button "Send"
  end

  step "I should see my message in the conversation" do
    expect(page).to have_content(@reply_message)
  end

  step "I close the conversation" do
    click_button "Archive"
  end

  step "the conversation should be archived" do
    expect(@conversation.reload).to be_archived
  end
end

RSpec.configure { |c| c.include WebManagingConversationSteps }
