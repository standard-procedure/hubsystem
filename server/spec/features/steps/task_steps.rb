# frozen_string_literal: true

module TaskSteps
  def self.included(base)
    base.fixtures :users, :user_sessions, :user_identities, :oauth_applications, :oauth_access_tokens
  end
end
