# frozen_string_literal: true

module TaskSteps
  def self.included(base)
    base.fixtures :users, :user_sessions, :user_identities
  end
end
