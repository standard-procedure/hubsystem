class Memory < ApplicationRecord
  SCOPES = %w[personal class_memory knowledge_base].freeze

  belongs_to :participant

  attribute :embedding, :embedding_vector

  validates :scope, presence: true, inclusion: { in: SCOPES }
  validates :content, presence: true
end
