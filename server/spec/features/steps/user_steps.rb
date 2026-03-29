# frozen_string_literal: true

module UserSteps
  def self.included(base)
    base.fixtures :users, :humans, :synthetics, :synthetic_classes, :user_sessions, :user_identities
  end
end
