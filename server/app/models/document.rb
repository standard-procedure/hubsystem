# frozen_string_literal: true

class Document < ApplicationRecord
  include Embeddable

  belongs_to :author, class_name: "User"

  validates :title, presence: true
  validates :content, presence: true

  scope :tagged_with, ->(tag) { where("? = ANY(tags)", tag) }
  scope :search, ->(query) {
    sanitized = sanitize_sql_like(query)
    where("content ILIKE ? OR title ILIKE ?", "%#{sanitized}%", "%#{sanitized}%")
  }
  scope :recent, -> { order(updated_at: :desc) }

  def embeddable_text
    "#{title}\n\n#{content}"
  end

  def embedding_content_changed?
    saved_change_to_title? || saved_change_to_content?
  end
end
