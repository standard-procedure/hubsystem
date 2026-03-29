# frozen_string_literal: true

require "rails_helper"

RSpec.describe TaskReminderJob, type: :job do
  fixtures :users, :humans, :synthetics, :synthetic_classes, :conversations, :messages

  let(:alice) { users(:alice) }
  let(:bob) { users(:bob) }
  let(:bishop) { users(:bishop) }

  describe "#perform" do
    it "sends a reminder for overdue tasks using an existing conversation" do
      # alice and bob already have alice_bob_active from fixtures
      Task.create!(creator: alice, assignee: bob, subject: "Review PR", due_at: 1.hour.ago)

      expect {
        described_class.perform_now
      }.to change(Message, :count).by(1)

      message = Message.last
      expect(message.content).to include("Reminder")
      expect(message.content).to include("Review PR")
    end

    it "skips tasks that are not yet due" do
      Task.create!(creator: alice, assignee: bob, subject: "Future task", due_at: 1.hour.from_now)

      expect {
        described_class.perform_now
      }.not_to change(Message, :count)
    end

    it "skips tasks without an active conversation between creator and assignee" do
      # bishop has no active conversation with alice
      Task.create!(creator: alice, assignee: bishop, subject: "No convo task", due_at: 1.hour.ago)

      expect {
        described_class.perform_now
      }.not_to change(Message, :count)
    end

    it "skips completed tasks" do
      Task.create!(creator: alice, assignee: bob, subject: "Done", due_at: 1.hour.ago, status: :completed, completed_at: Time.current)

      expect {
        described_class.perform_now
      }.not_to change(Message, :count)
    end
  end
end
