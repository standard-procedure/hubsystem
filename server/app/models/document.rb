# frozen_string_literal: true

class Document < ApplicationRecord
  has_neighbors :embedding

  belongs_to :author, class_name: "User"

  validates :title, presence: true
  validates :content, presence: true

  scope :tagged_with, ->(tag) { where("? = ANY(tags)", tag) }
  scope :search, ->(query) {
    sanitized = sanitize_sql_like(query)
    where("content ILIKE ? OR title ILIKE ?", "%#{sanitized}%", "%#{sanitized}%")
  }
  scope :recent, -> { order(updated_at: :desc) }
end
