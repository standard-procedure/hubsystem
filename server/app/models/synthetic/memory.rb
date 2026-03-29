# frozen_string_literal: true

class Synthetic::Memory < ApplicationRecord
  self.table_name = "synthetic_memories"

  include Embeddable

  belongs_to :synthetic

  validates :content, presence: true

  scope :tagged_with, ->(tag) { where("? = ANY(tags)", tag) }
  scope :search, ->(query) {
    sanitized = sanitize_sql_like(query)
    where("content ILIKE ?", "%#{sanitized}%")
  }
  scope :recent, -> { order(created_at: :desc) }

  def embeddable_text
    content
  end

  def embedding_content_changed?
    saved_change_to_content?
  end
end
