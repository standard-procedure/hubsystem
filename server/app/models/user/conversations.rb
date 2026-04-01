module User::Conversations
  extend ActiveSupport::Concern

  included do
    has_many :sent_messages, -> { order :created_at }, class_name: "Conversation::Message", inverse_of: :sender, dependent: :destroy
    has_many :conversation_memberships, class_name: "Conversation::Participant", inverse_of: :user, dependent: :destroy
    has_many :conversations, -> { order :created_at }, through: :conversation_memberships
  end
end
