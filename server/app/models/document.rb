# frozen_string_literal: true

class Document < ApplicationRecord
  belongs_to :author, class_name: "User"

  validates :title, presence: true
  validates :content, presence: true

  scope :tagged_with, ->(tag) { where("json_each.value = ?", tag).joins("JOIN json_each(tags) AS json_each") }
  scope :search, ->(query) {
    sanitized = sanitize_sql_like(query)
    where("content LIKE ? OR title LIKE ?", "%#{sanitized}%", "%#{sanitized}%")
  }
  scope :recent, -> { order(updated_at: :desc) }
end
