module ConversationSteps
  step "I have logged in as Alice" do
  end

  step "I ask Bob to start a conversation" do
    post api_v1_user_conversations(users(:bob), params: {conversation: {subject: "Hello"}}), headers: auth_header(oauth_access_tokens(:alice))
    data = JSON.parse(response.body)
    @conversation_request = ConversationRequst.find data[:id]
  end

  step "Bob accepts the request" do
    post api_v1_accept_conversation_request_path(@conversation_request), headers: auth_header(oauth_access_tokens(:bob))
  end

  step "I send Bob a message" do
    post api_v1_conversation_messages_path(@conversation_request), params: {message: {contents: "How are you?"}}, headers: auth_header(oauth_access_tokens(:alice))
  end

  step "Bob should receive my message" do
    get api_v1_user_messages(users(:bob)), headers: auth_header(oauth_access_tokens(:bob))
  end
end
