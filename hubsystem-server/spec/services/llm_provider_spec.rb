require "rails_helper"

RSpec.describe LLMProvider do
  describe ".stub?" do
    it "returns true in test environment" do
      expect(described_class.stub?).to be(true)
    end
  end

  describe ".for_role" do
    it "returns a callable" do
      result = described_class.for_role(:main_turn)
      expect(result).to respond_to(:call)
    end

    it "returns stub response in test environment" do
      callable = described_class.for_role(:main_turn)
      expect(callable.call("system prompt", "user message")).to eq(LLMProvider::STUB_RESPONSE)
    end

    it "returns stub response for any role in test environment" do
      callable = described_class.for_role(:security_eval)
      expect(callable.call("system", "message")).to eq(LLMProvider::STUB_RESPONSE)
    end
  end

  describe ".embedding_provider" do
    it "returns a callable" do
      result = described_class.embedding_provider
      expect(result).to respond_to(:call)
    end

    it "returns a 1536-dimensional array in test environment" do
      callable = described_class.embedding_provider
      embedding = callable.call("some text")
      expect(embedding).to be_an(Array)
      expect(embedding.length).to eq(1536)
    end

    it "returns float values" do
      callable = described_class.embedding_provider
      embedding = callable.call("some text")
      expect(embedding).to all(be_a(Numeric))
    end
  end
end
