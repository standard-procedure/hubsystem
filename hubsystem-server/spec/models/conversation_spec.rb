require "rails_helper"

RSpec.describe Conversation, type: :model do
  describe "associations" do
    it { should have_many(:conversation_memberships) }
    it { should have_many(:participants).through(:conversation_memberships) }
    it { should have_many(:messages) }
  end
end
