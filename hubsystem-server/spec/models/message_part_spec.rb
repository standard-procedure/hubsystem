require "rails_helper"

RSpec.describe MessagePart, type: :model do
  describe "associations" do
    it { should belong_to(:message) }
  end

  describe "validations" do
    subject { build(:message_part) }

    it { should validate_presence_of(:content_type) }
  end
end
