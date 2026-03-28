# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :sender, class_name: "User"

  validates :content, presence: true

  scope :unread, -> { where(read_at: nil) }

  def mark_as_read!
    update!(read_at: Time.current) if read_at.nil?
  end
end
