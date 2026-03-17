class Group < ApplicationRecord
  GROUP_TYPES = %w[account department team].freeze

  validates :name, presence: true
  validates :group_type, presence: true, inclusion: { in: GROUP_TYPES }
  validates :slug, uniqueness: { allow_nil: true }

  has_many :security_passes
  has_many :participants, through: :security_passes
end
