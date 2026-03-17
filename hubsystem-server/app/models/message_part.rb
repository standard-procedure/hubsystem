class MessagePart < ApplicationRecord
  belongs_to :message

  validates :content_type, presence: true
end
