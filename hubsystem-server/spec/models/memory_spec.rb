require "rails_helper"

RSpec.describe Memory, type: :model do
  describe "associations" do
    it { should belong_to(:participant) }
  end

  describe "validations" do
    subject { build(:memory) }

    it { should validate_presence_of(:scope) }
    it { should validate_presence_of(:content) }
    it { should validate_inclusion_of(:scope).in_array(%w[personal class_memory knowledge_base]) }
  end
end
