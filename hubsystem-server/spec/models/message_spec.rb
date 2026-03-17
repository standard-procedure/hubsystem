require "rails_helper"

RSpec.describe Message, type: :model do
  describe "associations" do
    it { should belong_to(:from).class_name("Participant") }
    it { should belong_to(:to).class_name("Participant") }
    it { should belong_to(:conversation).optional }
    it { should have_many(:parts).class_name("MessagePart") }
  end
end
