# frozen_string_literal: true

class User::Session < ApplicationRecord
  belongs_to :user, inverse_of: :sessions
end
