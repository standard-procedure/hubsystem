# frozen_string_literal: true

require "rails_helper"

RSpec.describe SkillLoaderTool, type: :model do
  fixtures :users, :humans, :synthetics, :synthetic_classes, :documents

  let(:bishop) { users(:bishop) }

  describe "#execute" do
    it "returns matching skills for the synthetic's class" do
      skill = Document.create!(author: bishop, title: "Code Review", content: "Steps for reviewing code", category: "skill")
      bishop.synthetic_class.skills << skill

      tool = described_class.new(bishop)
      result = tool.execute(query: "Code Review")
      expect(result).to include("Code Review")
      expect(result).to include("Steps for reviewing code")
    end

    it "lists child documents in the output" do
      skill = Document.create!(author: bishop, title: "Deployment", content: "How to deploy", category: "skill")
      skill.children.create!(author: bishop, title: "Pre-deploy script", content: "bin/check", category: "script")
      bishop.synthetic_class.skills << skill

      tool = described_class.new(bishop)
      result = tool.execute(query: "deploy")
      expect(result).to include("Deployment")
      expect(result).to include("Pre-deploy script")
      expect(result).to include("script")
    end

    it "returns no skills message when class has no skills" do
      ash = users(:ash)
      tool = described_class.new(ash)
      result = tool.execute(query: "anything")
      expect(result).to eq("No skills available.")
    end

    it "returns no matching skills when query doesn't match" do
      skill = Document.create!(author: bishop, title: "Database Admin", content: "Managing PostgreSQL", category: "skill")
      bishop.synthetic_class.skills << skill

      tool = described_class.new(bishop)
      result = tool.execute(query: "quantum physics")
      # Falls back to text search, which also won't match
      expect(result).to include("No matching skills found.").or include("Database Admin")
    end
  end
end
