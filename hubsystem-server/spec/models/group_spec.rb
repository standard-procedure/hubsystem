require "rails_helper"

RSpec.describe Group, type: :model do
  describe "validations" do
    subject { build(:group) }

    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:group_type) }
    it { should validate_inclusion_of(:group_type).in_array(%w[account department team]) }
  end

  describe "associations" do
    it { should have_many(:security_passes) }
    it { should have_many(:participants).through(:security_passes) }
  end
end
