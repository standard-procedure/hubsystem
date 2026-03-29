# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Document tools", type: :model do
  fixtures :users, :humans, :synthetics, :synthetic_classes, :documents

  let(:bishop) { users(:bishop) }

  describe ReadDocumentTool do
    it "searches by query" do
      tool = described_class.new(bishop)
      result = tool.execute(query: "deploy")
      expect(result).to include("Deploy Guide")
    end

    it "searches by tag" do
      tool = described_class.new(bishop)
      result = tool.execute(tag: "api")
      expect(result).to include("API Reference")
      expect(result).not_to include("Deploy Guide")
    end

    it "returns no documents message when empty" do
      tool = described_class.new(bishop)
      result = tool.execute(tag: "nonexistent")
      expect(result).to eq("No documents found.")
    end
  end

  describe WriteDocumentTool do
    let(:tool) { described_class.new(bishop) }

    it "creates a document" do
      expect {
        result = tool.execute(title: "New Doc", content: "Some content", tags: "guide, ops")
        expect(result).to include("Document created")
        expect(result).to include("New Doc")
      }.to change(Document, :count).by(1)

      doc = Document.last
      expect(doc.author).to eq(bishop)
      expect(doc.tags).to eq(["guide", "ops"])
    end
  end
end
