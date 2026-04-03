class Conversation::Message < ApplicationRecord
  include HasTags
  include HasAttachments
  include HasStatusBadge

  belongs_to :conversation, inverse_of: :messages
  delegate :participants, to: :conversation
  belongs_to :sender, class_name: "User", inverse_of: :sent_messages
  validate :sender_belongs_to_conversation, if: -> { sender_id_changed? }
  has_many :message_readings, dependent: :destroy
  has_attachments :attachments
  broadcasts_refreshes_to :conversation

  def to_s = excerpt
  def to_param = "#{id}-#{excerpt}".parameterize
  def excerpt = contents.to_s.split("\n").first
  def embeddable_text = contents.to_s
  def embedding_content_changed? = contents_changed?
  def read_by?(user) = message_readings.find { |mr| mr.user == user }

  def send_reply sender:, contents:, status_badge: :online, attachments: []
    conversation.send_message sender:, contents:, status_badge:, attachments:
  end

  private def sender_belongs_to_conversation
    errors.add :sender, :invalid unless conversation.users.include? sender
  end
end
