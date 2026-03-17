class Conversation < ApplicationRecord
  has_many :conversation_memberships, dependent: :destroy
  has_many :participants, through: :conversation_memberships
  has_many :messages, dependent: :destroy
end
