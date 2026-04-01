module User::Conversations
  extend ActiveSupport::Concern

  included do
    has_many :sent_messages, -> { order :created_at }, class_name: "Conversation::Message", inverse_of: :sender, dependent: :destroy
    has_many :conversation_memberships, class_name: "Conversation::Participant", inverse_of: :user, dependent: :destroy
    has_many :conversations, -> { order :created_at }, through: :conversation_memberships
    has_many :messages, -> { order :created_at }, through: :conversations
    has_many :message_readings, class_name: "Conversation::MessageReading", dependent: :destroy
    has_many :read_messages, -> { order :created_at }, through: :message_readings, source: :message
  end

  def unread_messages = messages.where.not(id: message_readings.pluck(:message_id)).order(:created_at)

  def start_conversation message:, subject: nil, with: []
    users = Array.wrap(with)
    _check subject, is: _String?
    _check message, is: String
    _check users, is: _Array(User)

    subject ||= message.to_s.split("\n").first.to_s

    transaction do
      Conversation.involving(users).first_or_create!(subject: subject).tap do |c|
        c.add self, participant_type: :admin
        users.each do |user|
          c.add user
        end
        c.send_message sender: self, contents: message
      end
    end
  end
end
