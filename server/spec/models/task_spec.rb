# frozen_string_literal: true

require "rails_helper"

RSpec.describe Task, type: :model do
  fixtures :users

  let(:alice) { users(:alice) }
  let(:bob) { users(:bob) }
  let(:bishop) { users(:bishop) }

  describe "validations" do
    it "requires a subject" do
      task = Task.new(creator: alice, subject: nil)
      expect(task).not_to be_valid
      expect(task.errors[:subject]).to include("can't be blank")
    end
  end

  describe "associations" do
    it "belongs to a creator" do
      task = Task.create!(creator: alice, subject: "Do something")
      expect(task.creator).to eq(alice)
    end

    it "optionally belongs to an assignee" do
      task = Task.create!(creator: alice, assignee: bob, subject: "Do something")
      expect(task.assignee).to eq(bob)
    end

    it "supports parent/children hierarchy" do
      parent = Task.create!(creator: alice, subject: "Parent")
      child = Task.create!(creator: alice, subject: "Child", parent: parent)
      expect(parent.children).to include(child)
      expect(child.parent).to eq(parent)
    end
  end

  describe "status" do
    it "defaults to pending" do
      task = Task.create!(creator: alice, subject: "New task")
      expect(task).to be_pending
    end
  end

  describe "#complete!" do
    it "marks the task as completed with a timestamp" do
      task = Task.create!(creator: alice, subject: "Do it")
      task.complete!
      expect(task).to be_completed
      expect(task.completed_at).to be_present
    end

    it "does nothing if already completed" do
      task = Task.create!(creator: alice, subject: "Done", status: :completed, completed_at: 1.day.ago)
      original_time = task.completed_at
      task.complete!
      expect(task.completed_at).to eq(original_time)
    end

    it "auto-completes parent when all children are completed" do
      parent = Task.create!(creator: alice, subject: "Parent")
      child1 = Task.create!(creator: alice, subject: "Child 1", parent: parent)
      child2 = Task.create!(creator: alice, subject: "Child 2", parent: parent)

      child1.complete!
      expect(parent.reload).to be_pending

      child2.complete!
      expect(parent.reload).to be_completed
    end

    it "auto-completes parent when remaining children are cancelled" do
      parent = Task.create!(creator: alice, subject: "Parent")
      child1 = Task.create!(creator: alice, subject: "Child 1", parent: parent)
      child2 = Task.create!(creator: alice, subject: "Child 2", parent: parent)

      child1.complete!
      child2.cancel!
      expect(parent.reload).to be_completed
    end

    it "cascades parent completion recursively" do
      grandparent = Task.create!(creator: alice, subject: "Grandparent")
      parent = Task.create!(creator: alice, subject: "Parent", parent: grandparent)
      child = Task.create!(creator: alice, subject: "Child", parent: parent)

      child.complete!
      expect(parent.reload).to be_completed
      expect(grandparent.reload).to be_completed
    end

    it "notifies the creator when assigned task completes" do
      task = Task.create!(creator: alice, assignee: bob, subject: "Review PR")

      expect {
        task.complete!
      }.to change(Message, :count).by(1)

      message = Message.last
      expect(message.content).to include("completed")
      expect(message.content).to include("Review PR")
    end
  end

  describe "#cancel!" do
    it "marks the task as cancelled" do
      task = Task.create!(creator: alice, subject: "Nope")
      task.cancel!
      expect(task).to be_cancelled
      expect(task.completed_at).to be_present
    end

    it "cascades cancellation to children" do
      parent = Task.create!(creator: alice, subject: "Parent")
      child1 = Task.create!(creator: alice, subject: "Child 1", parent: parent)
      child2 = Task.create!(creator: alice, subject: "Child 2", parent: parent)

      parent.cancel!
      expect(child1.reload).to be_cancelled
      expect(child2.reload).to be_cancelled
    end

    it "does not cancel already completed children" do
      parent = Task.create!(creator: alice, subject: "Parent")
      child1 = Task.create!(creator: alice, subject: "Done child", parent: parent, status: :completed, completed_at: 1.hour.ago)
      child2 = Task.create!(creator: alice, subject: "Pending child", parent: parent)

      parent.cancel!
      expect(child1.reload).to be_completed
      expect(child2.reload).to be_cancelled
    end
  end

  describe "#blocked?" do
    it "returns false when no dependencies" do
      task = Task.create!(creator: alice, subject: "Free task")
      expect(task).not_to be_blocked
    end

    it "returns true when dependencies are incomplete" do
      dep = Task.create!(creator: alice, subject: "Prerequisite")
      task = Task.create!(creator: alice, subject: "Blocked task")
      task.dependencies << dep

      expect(task).to be_blocked
    end

    it "returns false when all dependencies are completed" do
      dep = Task.create!(creator: alice, subject: "Prerequisite", status: :completed, completed_at: Time.current)
      task = Task.create!(creator: alice, subject: "Unblocked task")
      task.dependencies << dep

      expect(task).not_to be_blocked
    end

    it "returns false when dependencies are cancelled" do
      dep = Task.create!(creator: alice, subject: "Cancelled dep", status: :cancelled, completed_at: Time.current)
      task = Task.create!(creator: alice, subject: "Unblocked task")
      task.dependencies << dep

      expect(task).not_to be_blocked
    end
  end

  describe "scopes" do
    describe ".due" do
      it "returns pending tasks with due_at in the past" do
        due = Task.create!(creator: alice, subject: "Overdue", due_at: 1.hour.ago)
        future = Task.create!(creator: alice, subject: "Future", due_at: 1.hour.from_now)
        no_due = Task.create!(creator: alice, subject: "No due date")

        expect(Task.due).to include(due)
        expect(Task.due).not_to include(future)
        expect(Task.due).not_to include(no_due)
      end
    end

    describe ".assigned_to" do
      it "returns tasks assigned to a user" do
        assigned = Task.create!(creator: alice, assignee: bob, subject: "Bob's task")
        other = Task.create!(creator: alice, assignee: alice, subject: "Alice's task")

        expect(Task.assigned_to(bob)).to include(assigned)
        expect(Task.assigned_to(bob)).not_to include(other)
      end
    end
  end
end
