# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Notes", type: :request do
  fixtures :users, :humans, :synthetics, :synthetic_classes, :user_sessions

  before { sign_in_as user_sessions(:alice_session) }

  let(:bishop) { users(:bishop) }

  describe "POST /users/:user_id/notes" do
    it "creates a private note" do
      expect {
        post user_notes_path(bishop), params: {note: {content: "Good analyst", visibility: "private"}}
      }.to change(Note, :count).by(1)

      note = Note.last
      expect(note.content).to eq("Good analyst")
      expect(note.personal?).to be true
      expect(note.author).to eq(users(:alice))
      expect(response).to redirect_to(user_path(bishop))
    end

    it "creates a public note" do
      post user_notes_path(bishop), params: {note: {content: "Great collaborator", visibility: "public"}}
      expect(Note.last.public_note?).to be true
    end
  end

  describe "PATCH /users/:user_id/notes/:id" do
    it "updates the note" do
      note = Note.create!(subject: bishop, author: users(:alice), content: "Original")
      patch user_note_path(bishop, note), params: {note: {content: "Updated"}}
      expect(note.reload.content).to eq("Updated")
      expect(response).to redirect_to(user_path(bishop))
    end

    it "prevents editing notes by other authors" do
      note = Note.create!(subject: bishop, author: users(:bob), content: "Bob's note")
      patch user_note_path(bishop, note), params: {note: {content: "Hacked"}}
      expect(response).to redirect_to(user_path(bishop))
      expect(note.reload.content).to eq("Bob's note")
    end
  end

  describe "DELETE /users/:user_id/notes/:id" do
    it "deletes the note" do
      note = Note.create!(subject: bishop, author: users(:alice), content: "Delete me")
      expect {
        delete user_note_path(bishop, note)
      }.to change(Note, :count).by(-1)
    end

    it "prevents deleting notes by other authors" do
      note = Note.create!(subject: bishop, author: users(:bob), content: "Bob's note")
      expect {
        delete user_note_path(bishop, note)
      }.not_to change(Note, :count)
    end
  end
end
