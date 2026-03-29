# frozen_string_literal: true

class Note < ApplicationRecord
  belongs_to :subject, class_name: "User"
  belongs_to :author, class_name: "User"

  enum :visibility, personal: "private", public_note: "public"

  validates :content, presence: true

  scope :visible_to, ->(user) { where(visibility: :public).or(where(author: user)) }
  scope :recent, -> { order(updated_at: :desc) }
end
