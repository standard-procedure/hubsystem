# frozen_string_literal: true

require "rails_helper"

RSpec.describe Document, type: :model do
  fixtures :users

  let(:bishop) { users(:bishop) }

  describe "validations" do
    it "requires a title" do
      doc = Document.new(author: bishop, title: nil, content: "Body")
      expect(doc).not_to be_valid
      expect(doc.errors[:title]).to include("can't be blank")
    end

    it "requires content" do
      doc = Document.new(author: bishop, title: "Title", content: nil)
      expect(doc).not_to be_valid
      expect(doc.errors[:content]).to include("can't be blank")
    end
  end

  describe "associations" do
    it "belongs to an author" do
      doc = Document.create!(author: bishop, title: "Guide", content: "How to do things", tags: ["guide"])
      expect(doc.author).to eq(bishop)
    end
  end

  describe "scopes" do
    before do
      Document.create!(author: bishop, title: "Deployment Guide", content: "How to deploy the app", tags: ["ops", "guide"])
      Document.create!(author: bishop, title: "API Reference", content: "Endpoint documentation", tags: ["api", "guide"])
      Document.create!(author: users(:alice), title: "Meeting Notes", content: "Discussed deployment timeline", tags: ["meetings"])
    end

    describe ".tagged_with" do
      it "returns documents matching a tag" do
        expect(Document.tagged_with("guide").count).to eq(2)
      end
    end

    describe ".search" do
      it "matches on content" do
        expect(Document.search("deploy").count).to eq(2)
      end

      it "matches on title" do
        expect(Document.search("Meeting").count).to eq(1)
      end
    end

    describe ".recent" do
      it "orders by updated_at descending" do
        expect(Document.recent.first.title).to eq("Meeting Notes")
      end
    end
  end
end
