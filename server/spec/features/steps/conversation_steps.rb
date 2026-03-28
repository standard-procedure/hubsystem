# frozen_string_literal: true

module ConversationSteps
  def self.included(base)
    base.fixtures :users, :user_sessions, :user_identities, :conversations, :messages, :oauth_applications, :oauth_access_tokens
  end

  def current_conversation
    @current_conversation
  end
end
