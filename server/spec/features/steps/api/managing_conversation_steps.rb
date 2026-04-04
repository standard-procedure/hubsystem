# frozen_string_literal: true

module ApiManagingConversationSteps
  extend Turnip::DSL

  step "I am logged in" do
    @user = users(:alice)
    @target_user = users(:dave)
    @new_subject = "Hello Dave"
    @new_message = "How are you doing?"
    @reply_message = "This is a new reply"
    @in_conversation_search = "Alice"
    @auth_token = oauth_access_tokens(:alice)
    @auth_headers = auth_header(@auth_token)
  end

  step "I start a new conversation" do
    # No-op for API — creation happens in "I send the conversation"
  end

  step "I search for a user" do
    # No-op for API — user selection is part of conversation creation
  end

  step "I select a user to talk to" do
    # No-op for API — user is specified in creation params
  end

  step "I fill in the subject and message" do
    # No-op for API — params are sent with creation request
  end

  step "I send the conversation" do
    post api_v1_conversations_path, params: {
      conversation: {subject: @new_subject, message: @new_message, participant_ids: [@target_user.id]}
    }, headers: @auth_headers, as: :json
    expect(response).to have_http_status(:created)
    @created_conversation = JSON.parse(response.body)
  end

  step "I should see the new conversation with my message" do
    get api_v1_conversation_path(@created_conversation["id"]), headers: @auth_headers
    body = JSON.parse(response.body)
    expect(body["subject"]).to eq(@new_subject)
    expect(body["messages"].any? { |m| m["contents"] == @new_message }).to be true
  end

  step "I view the conversation" do
    get api_v1_conversation_path(@conversation), headers: @auth_headers
    expect(response).to have_http_status(:ok)
  end

  step "I send a message" do
    post api_v1_conversation_messages_path(@conversation),
      params: {message: {contents: @reply_message}},
      headers: @auth_headers, as: :json
    expect(response).to have_http_status(:created)
  end

  step "I should see my message in the conversation" do
    get api_v1_conversation_path(@conversation), headers: @auth_headers
    body = JSON.parse(response.body)
    expect(body["messages"].any? { |m| m["contents"] == @reply_message }).to be true
  end

  step "I search for a message within the conversation" do
    get api_v1_conversation_messages_path(@conversation, search: @in_conversation_search), headers: @auth_headers
    @search_results = JSON.parse(response.body)
  end

  step "I should only see matching messages" do
    matching_ids = @conversation.messages.where("contents ILIKE ?", "%#{@in_conversation_search}%").pluck(:id)
    result_ids = @search_results.map { |m| m["id"] }
    expect(result_ids).to match_array(matching_ids)
  end

  step "I close the conversation" do
    patch api_v1_conversation_path(@conversation),
      params: {conversation: {status: "archived"}},
      headers: @auth_headers, as: :json
    expect(response).to have_http_status(:ok)
  end

  step "the conversation should be archived" do
    expect(@conversation.reload).to be_archived
  end
end

RSpec.configure { |c| c.include ApiManagingConversationSteps }
