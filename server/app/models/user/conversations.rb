module User::Conversations
  extend ActiveSupport::Concern

  included do
    has_many :sent_messages, -> { order(Arel.sql("conversation_messages.created_at desc")) }, class_name: "Conversation::Message", inverse_of: :sender, dependent: :destroy
    has_many :conversation_memberships, class_name: "Conversation::Participant", inverse_of: :user, dependent: :destroy
    has_many :conversations, -> { eager_load(participants: :user, messages: {message_readings: :user}).order "conversations.created_at desc" }, through: :conversation_memberships
    has_many :messages, -> { eager_load(:conversation, message_readings: :user).order(Arel.sql("conversation_messages.created_at desc")) }, through: :conversations
    has_many :message_readings, class_name: "Conversation::MessageReading", dependent: :destroy
    has_many :read_messages, -> { order(Arel.sql("conversation_messages.created_at desc")) }, through: :message_readings, source: :message, class_name: "Conversation::Message"
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
