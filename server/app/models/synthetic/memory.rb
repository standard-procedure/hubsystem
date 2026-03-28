# frozen_string_literal: true

class Synthetic::Memory < ApplicationRecord
  self.table_name = "synthetic_memories"

  belongs_to :synthetic, class_name: "User::Synthetic"

  validates :content, presence: true

  scope :tagged_with, ->(tag) { where("json_each.value = ?", tag).joins("JOIN json_each(tags) AS json_each") }
  scope :search, ->(query) { where("content LIKE ?", "%#{query}%") }
  scope :recent, -> { order(created_at: :desc) }
end
