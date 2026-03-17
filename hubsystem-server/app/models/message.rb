class Message < ApplicationRecord
  belongs_to :from, class_name: "Participant"
  belongs_to :to, class_name: "Participant"
  belongs_to :conversation, optional: true

  has_many :parts, class_name: "MessagePart", dependent: :destroy
end
