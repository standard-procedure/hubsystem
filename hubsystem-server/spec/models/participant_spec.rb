require "rails_helper"

RSpec.describe Participant, type: :model do
  describe "validations" do
    subject { build(:human_participant) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:slug) }
    it { should validate_uniqueness_of(:slug) }
  end

  describe "associations" do
    it { should have_many(:inbox_messages).class_name("Message").with_foreign_key(:to_id) }
    it { should have_many(:outbox_messages).class_name("Message").with_foreign_key(:from_id) }
    it { should have_many(:security_passes) }
    it { should have_many(:groups).through(:security_passes) }
    it { should have_many(:conversation_memberships) }
    it { should have_many(:conversations).through(:conversation_memberships) }
  end
end
