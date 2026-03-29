# frozen_string_literal: true

class SyntheticClass < ApplicationRecord
  has_many :synthetics, dependent: :nullify
  has_many :class_memories, -> { where(scope: :class_memory) },
    class_name: "Synthetic::Memory", dependent: :destroy
  has_and_belongs_to_many :skills, class_name: "Document",
    join_table: :synthetic_class_skills,
    foreign_key: :synthetic_class_id,
    association_foreign_key: :document_id

  validates :name, presence: true
  validates :llm_tier, presence: true, inclusion: {in: %w[low medium high]}
end
