class Conversation::Participant < ApplicationRecord
  belongs_to :conversation, inverse_of: :participants
  belongs_to :user, inverse_of: :conversation_memberships
  enum :participant_type, member: 0, admin: 100

  def to_s = participant_type
  def to_param = "#{id}-#{participant_type}".parameterize
end
