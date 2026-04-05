# frozen_string_literal: true

require "rails_helper"

RSpec.describe HubSystem::HasTypeChecks do
  let(:test_class) do
    Class.new do
      include HubSystem::HasTypeChecks
    end
  end

  describe "#_check" do
    it "passes when value matches the type" do
      expect { test_class.new._check("hello", is: String) }.not_to raise_error
    end

    it "raises ArgumentError when value does not match the type" do
      expect { test_class.new._check(42, is: String) }.to raise_error(ArgumentError)
    end

    it "works with proc-based type constraints" do
      positive = proc { |v| v > 0 }
      expect { test_class.new._check(5, is: positive) }.not_to raise_error
      expect { test_class.new._check(-1, is: positive) }.to raise_error(ArgumentError)
    end
  end

  describe "class method" do
    it "is available as a class method" do
      expect { test_class._check("hello", is: String) }.not_to raise_error
    end

    it "raises ArgumentError as a class method" do
      expect { test_class._check(42, is: String) }.to raise_error(ArgumentError)
    end
  end
end
