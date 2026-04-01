# frozen_string_literal: true

require "rails_helper"

RSpec.describe HasTags do
  # Tested through Conversation which includes it.
  fixtures :conversations

  describe ".tagged_with" do
    it "returns records that include the tag" do
      conversations(:alpha).update!(tags: ["urgent", "project"])
      conversations(:beta).update!(tags: ["project"])

      expect(Conversation.tagged_with("urgent")).to contain_exactly(conversations(:alpha))
      expect(Conversation.tagged_with("project")).to include(conversations(:alpha), conversations(:beta))
    end

    it "does not return records missing the tag" do
      conversations(:alpha).update!(tags: ["urgent"])

      expect(Conversation.tagged_with("urgent")).not_to include(conversations(:beta))
    end

    it "returns nothing when no records have the tag" do
      expect(Conversation.tagged_with("nonexistent")).to be_empty
    end
  end

  describe "tags column" do
    it "defaults to an empty array" do
      expect(Conversation.new.tags).to eq([])
    end

    it "stores multiple tags" do
      conversations(:alpha).update!(tags: ["a", "b", "c"])
      expect(conversations(:alpha).reload.tags).to eq(["a", "b", "c"])
    end
  end
end
