# frozen_string_literal: true

require "rails_helper"

RSpec.describe Note, type: :model do
  fixtures :users, :humans, :synthetics, :synthetic_classes

  let(:alice) { users(:alice) }
  let(:bob) { users(:bob) }
  let(:bishop) { users(:bishop) }

  describe "validations" do
    it "requires content" do
      note = Note.new(subject: bishop, author: alice, content: nil)
      expect(note).not_to be_valid
      expect(note.errors[:content]).to include("can't be blank")
    end
  end

  describe "associations" do
    it "belongs to a subject and author" do
      note = Note.create!(subject: bishop, author: alice, content: "Good at analysis")
      expect(note.subject).to eq(bishop)
      expect(note.author).to eq(alice)
    end
  end

  describe "scopes" do
    before do
      Note.create!(subject: bishop, author: alice, content: "Alice's private note", visibility: "private")
      Note.create!(subject: bishop, author: alice, content: "Alice's public note", visibility: "public")
      Note.create!(subject: bishop, author: bob, content: "Bob's private note", visibility: "private")
    end

    describe ".visible_to" do
      it "shows public notes and the user's own private notes" do
        results = Note.visible_to(alice)
        expect(results.count).to eq(2)
        expect(results.pluck(:content)).to contain_exactly("Alice's private note", "Alice's public note")
      end

      it "shows public notes and bob's own private notes to bob" do
        results = Note.visible_to(bob)
        expect(results.count).to eq(2)
        expect(results.pluck(:content)).to contain_exactly("Alice's public note", "Bob's private note")
      end
    end
  end

  describe "cascade delete" do
    it "is destroyed when the subject is destroyed" do
      Note.create!(subject: bishop, author: alice, content: "Test")
      expect { bishop.destroy }.to change(Note, :count).by(-1)
    end
  end
end
