# frozen_string_literal: true

class TaskReminderJob < ApplicationJob
  queue_as :default

  def perform
    Task.due.find_each do |task|
      notify_assignee(task)
    end
  end

  private

  def notify_assignee(task)
    user = task.assignee || task.creator
    conversation = find_notification_conversation(task.creator, user)
    return unless conversation

    message = "Reminder: #{task.subject} is due"
    message += "\n#{task.description}" if task.description.present?
    conversation.messages.create!(sender: task.creator, content: message)
  end

  def find_notification_conversation(creator, assignee)
    return nil if creator == assignee

    Conversation.involving(creator).involving(assignee).active.first
  end
end
