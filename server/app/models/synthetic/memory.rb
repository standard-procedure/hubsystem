# frozen_string_literal: true

class Synthetic::Memory < ApplicationRecord
  self.table_name = "synthetic_memories"

  include Embeddable

  belongs_to :synthetic, optional: true
  belongs_to :synthetic_class, optional: true

  enum :scope, personal: "personal", class_memory: "class_memory", knowledge_base: "knowledge_base"

  validates :content, presence: true
  validate :owner_present

  scope :for_synthetic, ->(synthetic) {
    where(scope: :personal, synthetic: synthetic)
      .or(where(scope: :class_memory, synthetic_class: synthetic.synthetic_class))
  }
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

  private

  def owner_present
    if personal? && synthetic_id.blank?
      errors.add(:synthetic, "must be present for personal memories")
    elsif class_memory? && synthetic_class_id.blank?
      errors.add(:synthetic_class, "must be present for class memories")
    end
  end
end
