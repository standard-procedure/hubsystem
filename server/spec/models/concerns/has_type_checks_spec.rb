# frozen_string_literal: true

require "rails_helper"

RSpec.describe HasTypeChecks do
  # Use a plain object rather than an AR model — the concern has no AR dependency.
  let(:checker) { Class.new { include HasTypeChecks }.new }

  describe "#_check (instance method)" do
    it "passes when the value satisfies the constraint" do
      expect { checker._check("hello", is: String) }.not_to raise_error
    end

    it "raises ArgumentError when the value does not satisfy the constraint" do
      expect { checker._check(42, is: String) }.to raise_error(ArgumentError, /42 fails type check/)
    end

    it "works with module inclusion as the constraint" do
      expect { checker._check(Conversation.new, is: HasTags) }.not_to raise_error
      expect { checker._check("not taggable", is: HasTags) }.to raise_error(ArgumentError)
    end
  end

  describe "._check (class method)" do
    let(:klass) { Class.new { include HasTypeChecks } }

    it "passes when the value satisfies the constraint" do
      expect { klass._check([], is: Array) }.not_to raise_error
    end

    it "raises ArgumentError when the value does not satisfy the constraint" do
      expect { klass._check("oops", is: Integer) }.to raise_error(ArgumentError, /oops fails type check/)
    end
  end
end
