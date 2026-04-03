# frozen_string_literal: true

module WebMessageSteps
  extend Turnip::DSL

  step "I log in" do
    session = user_sessions(:alice_session)
    jar = ActionDispatch::Request.new(Rails.application.env_config.dup).cookie_jar
    jar.signed[:session_id] = {value: session.id, httponly: true}
    page.driver.browser.set_cookie("session_id=#{jar[:session_id]}")
    visit root_path
  end

  step "I should see a count of my unread messages on the dashboard" do
    expect(page).to have_content(I18n.t("views.dashboard.show.unread_messages", count: @user.unread_messages.size))
  end

  step "I go to the messages tab" do
    click_link "Messages"
  end

  step "I should only see my unread messages" do
    @user.unread_messages.each do |message|
      expect(page).to have_content(message.excerpt)
    end
  end

  step "I select one of the unread messages" do
    @selected_message = @user.unread_messages.first
    click_link @selected_message.excerpt
  end

  step "I should see the conversation containing the message" do
    @selected_message.conversation.messages.each do |msg|
      expect(page).to have_content(msg.excerpt)
    end
  end

  step "I search for part of a previous message" do
    fill_in "search", with: @search_text
    click_button "Search"
  end

  step "I should see the conversations and matching messages" do
    expect(page).to have_content(@search_text)
  end

  step "I select one of the matching messages" do
    @selected_message = Conversation::Message.where("contents ILIKE ?", "%#{@search_text}%").first
    click_link @selected_message.excerpt
  end

  step "I search for the name of a user" do
    click_link "Conversations"
    fill_in "search", with: @search_user.name
    click_button "Search"
  end

  step "I should see the conversations I have had with that user" do
    search_user_conversation_ids = Conversation::Participant.where(user: @search_user).pluck(:conversation_id)
    @user.conversations.where(id: search_user_conversation_ids).each do |conv|
      expect(page).to have_content(conv.subject)
    end
  end

  step "I select one of the conversations" do
    conversation_link = page.all("a[href*='/conversations/']").first
    @selected_conversation_id = conversation_link[:href].match(/conversations\/(\d+)/)[1]
    @selected_conversation = Conversation.find(@selected_conversation_id)
    conversation_link.click
  end

  step "I should see the conversation and its messages" do
    @selected_conversation.messages.each do |msg|
      expect(page).to have_content(msg.excerpt)
    end
  end

  step "I view my conversations" do
    click_link "Conversations"
  end

  step "I view my archived conversations" do
    click_link "Archive"
  end
end

RSpec.configure { |c| c.include WebMessageSteps }
