class Participant < ApplicationRecord
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  has_many :inbox_messages, class_name: "Message", foreign_key: :to_id, dependent: :destroy
  has_many :outbox_messages, class_name: "Message", foreign_key: :from_id, dependent: :destroy
  has_many :security_passes
  has_many :groups, through: :security_passes
  has_many :memories, dependent: :destroy
  has_many :conversation_memberships, dependent: :destroy
  has_many :conversations, through: :conversation_memberships
end
