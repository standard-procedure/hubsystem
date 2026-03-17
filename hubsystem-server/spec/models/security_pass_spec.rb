require "rails_helper"

RSpec.describe SecurityPass, type: :model do
  describe "associations" do
    it { should belong_to(:participant) }
    it { should belong_to(:group) }
  end

  describe "defaults" do
    it "defaults capabilities to empty array" do
      pass = create(:security_pass)
      expect(pass.capabilities).to eq([])
    end
  end
end
