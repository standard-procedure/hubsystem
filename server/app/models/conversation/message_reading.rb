class Conversation::MessageReading < ApplicationRecord
  belongs_to :message
  belongs_to :user, inverse_of: :message_readings
end
