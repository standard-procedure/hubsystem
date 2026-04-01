class Conversation < ApplicationRecord
  include HasTags
  include HasStatusBadge

  validates :subject, presence: true
  normalizes :subject, with: ->(s) { s.to_s.strip }
  has_many :participants, -> { joins(:user).order(Arel.sql("users.name")) }, class_name: "Conversation::Participant", dependent: :destroy
  has_many :users, -> { order :name }, through: :participants
  has_many :messages, -> { eager_load(:sender, :attachments_attachments).order(Arel.sql("conversation_messages.created_at")) }, class_name: "Conversation::Message", dependent: :destroy
  enum :status, active: 0, archived: -1

  def to_s = subject
  def to_param = "#{id}-#{subject}".parameterize

  def add user, participant_type: :member
    participants.where(user: user).first_or_initialize do |participant|
      participant.update! participant_type:
    end
  end

  def remove user
    participants.where(user: user).destroy_all
  end

  def send_message sender:, contents:, status_badge: :online, attachments: []
    messages.create! sender:, contents:, status_badge:, attachments:
  end
end
