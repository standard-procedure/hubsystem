# frozen_string_literal: true

require "fugit"

class Task < ApplicationRecord
  belongs_to :creator, class_name: "User"
  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :parent, class_name: "Task", optional: true
  has_many :children, class_name: "Task", foreign_key: :parent_id, dependent: :destroy

  has_many :task_dependencies, dependent: :destroy
  has_many :dependencies, through: :task_dependencies, source: :dependency
  has_many :inverse_task_dependencies, class_name: "TaskDependency", foreign_key: :dependency_id, dependent: :destroy
  has_many :dependents, through: :inverse_task_dependencies, source: :task

  enum :status, pending: 0, in_progress: 1, completed: 2, cancelled: 3

  validates :subject, presence: true
  validate :schedule_is_valid_cron, if: -> { schedule.present? }

  scope :due, -> { pending.where(due_at: ..Time.current) }
  scope :assigned_to, ->(user) { where(assignee: user) }
  scope :created_by, ->(user) { where(creator: user) }
  scope :top_level, -> { where(parent_id: nil) }
  scope :tagged_with, ->(tag) { where("json_each.value = ?", tag).joins("JOIN json_each(tags) AS json_each") }

  def blocked?
    dependencies.where.not(status: [:completed, :cancelled]).exists?
  end

  def scheduled?
    schedule.present?
  end

  def next_due_at
    return nil unless scheduled?
    cron = Fugit::Cron.parse(schedule)
    return nil unless cron
    cron.next_time(Time.current).to_t
  end

  def complete!
    return if completed? || cancelled?

    update!(status: :completed, completed_at: Time.current)
    create_next_occurrence if scheduled?
    notify_creator("completed")
    check_parent_completion
  end

  def cancel!
    return if completed? || cancelled?

    update!(status: :cancelled, completed_at: Time.current)
    children.where.not(status: [:completed, :cancelled]).find_each(&:cancel!)
    notify_creator("cancelled")
    check_parent_completion
  end

  private

  def create_next_occurrence
    Task.create!(
      creator: creator,
      assignee: assignee,
      parent: parent,
      subject: subject,
      description: description,
      schedule: schedule,
      tags: tags,
      due_at: next_due_at
    )
  end

  def check_parent_completion
    return unless parent
    return if parent.children.where.not(status: [:completed, :cancelled]).exists?

    parent.complete!
  end

  def notify_creator(action)
    return if creator == assignee

    conversation = find_or_create_notification_conversation
    return unless conversation&.active?

    message = "Task #{action}: #{subject}"
    message += "\n#{description}" if description.present?
    conversation.messages.create!(sender: assignee || creator, content: message)
  end

  def schedule_is_valid_cron
    unless Fugit::Cron.parse(schedule)
      errors.add(:schedule, "is not a valid cron expression")
    end
  end

  def find_or_create_notification_conversation
    return nil unless assignee

    Conversation.involving(creator).involving(assignee).active.first ||
      Conversation.create(initiator: assignee, recipient: creator, subject: "Task notifications", status: :active)
  end
end
