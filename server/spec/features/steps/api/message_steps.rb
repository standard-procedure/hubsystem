# frozen_string_literal: true

module ApiMessageSteps
  extend Turnip::DSL

  step "I log in" do
    @auth_token = oauth_access_tokens(:alice)
    @auth_headers = auth_header(@auth_token)
  end

  step "I should see a count of my unread messages on the dashboard" do
    get api_v1_messages_path, headers: @auth_headers
    @messages_data = JSON.parse(response.body)
    expect(@messages_data.size).to eq(@user.unread_messages.size)
  end

  step "I go to the messages tab" do
    get api_v1_messages_path, headers: @auth_headers
    @messages_data = JSON.parse(response.body)
  end

  step "I should only see my unread messages" do
    response_ids = @messages_data.map { |m| m["id"] }
    expect(response_ids).to match_array(@user.unread_messages.map(&:id).uniq)
  end

  step "I select one of the unread messages" do
    @selected_message = @user.unread_messages.first
    get api_v1_message_path(@selected_message), headers: @auth_headers
    @message_detail = JSON.parse(response.body)
  end

  step "I should see the conversation containing the message" do
    conversation_message_ids = @message_detail["conversation"]["messages"].map { |m| m["id"] }
    expect(conversation_message_ids).to match_array(@selected_message.conversation.messages.pluck(:id))
  end

  step "I search for part of a previous message" do
    get api_v1_messages_path(search: @search_text), headers: @auth_headers
    @messages_data = JSON.parse(response.body)
  end

  step "I should see the conversations and matching messages" do
    expect(@messages_data.any? { |m| m["contents"].include?(@search_text) }).to be true
  end

  step "I select one of the matching messages" do
    @selected_message = Conversation::Message.find(@messages_data.first["id"])
    get api_v1_message_path(@selected_message), headers: @auth_headers
    @message_detail = JSON.parse(response.body)
  end

  step "I search for the name of a user" do
    get api_v1_conversations_path(search: @search_user.name), headers: @auth_headers
    @conversations_data = JSON.parse(response.body)
  end

  step "I should see the conversations I have had with that user" do
    user_conversation_ids = @user.conversations.pluck(:id).uniq
    search_user_conversation_ids = Conversation::Participant.where(user: @search_user).pluck(:conversation_id)
    expected_ids = user_conversation_ids & search_user_conversation_ids
    actual_ids = @conversations_data.map { |c| c["id"] }
    expect(actual_ids).to match_array(expected_ids)
  end

  step "I select one of the conversations" do
    @selected_conversation = Conversation.find(@conversations_data.first["id"])
    get api_v1_conversation_path(@selected_conversation), headers: @auth_headers
    @conversation_detail = JSON.parse(response.body)
  end

  step "I should see the conversation and its messages" do
    conversation_message_ids = @conversation_detail["messages"].map { |m| m["id"] }
    expect(conversation_message_ids).to match_array(@selected_conversation.messages.pluck(:id))
  end

  step "I view my conversations" do
    get api_v1_conversations_path, headers: @auth_headers
    @conversations_data = JSON.parse(response.body)
  end

  step "I view my archived conversations" do
    get api_v1_conversations_path(archived: true), headers: @auth_headers
    @conversations_data = JSON.parse(response.body)
  end
end

RSpec.configure { |c| c.include ApiMessageSteps }
