# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserActivityRefreshJob, type: :job do
  fixtures :users, :humans, :synthetics, :synthetic_classes

  describe "#perform" do
    it "broadcasts the user activity matrix" do
      expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to).with(
        :user_activity_matrix,
        target: "user_activity_matrix",
        renderable: an_instance_of(Components::UserActivityMatrix)
      )

      described_class.perform_now
    end
  end
end
