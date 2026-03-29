# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyntheticClass, type: :model do
  fixtures :synthetic_classes, :synthetics, :users, :humans

  describe "validations" do
    it "requires a name" do
      sc = SyntheticClass.new(name: nil, llm_tier: "low")
      expect(sc).not_to be_valid
      expect(sc.errors[:name]).to include("can't be blank")
    end

    it "requires a valid llm_tier" do
      sc = SyntheticClass.new(name: "Test", llm_tier: "ultra")
      expect(sc).not_to be_valid
      expect(sc.errors[:llm_tier]).to include("is not included in the list")
    end

    it "accepts low, medium, and high tiers" do
      %w[low medium high].each do |tier|
        sc = SyntheticClass.new(name: "Test", llm_tier: tier)
        expect(sc).to be_valid
      end
    end
  end

  describe "associations" do
    it "has many synthetics" do
      standard = synthetic_classes(:standard)
      expect(standard.synthetics).to include(synthetics(:bishop_synthetic))
    end

    it "nullifies synthetics on destroy" do
      standard = synthetic_classes(:standard)
      standard.destroy
      expect(synthetics(:bishop_synthetic).reload.synthetic_class_id).to be_nil
    end
  end

  describe "skills" do
    it "can have skill documents associated" do
      standard = synthetic_classes(:standard)
      skill = Document.create!(author: users(:alice), title: "Deploy Skill", content: "How to deploy", category: "skill")
      standard.skills << skill
      expect(standard.skills).to include(skill)
    end
  end
end
