# frozen_string_literal: true

module MessageSteps
  extend Turnip::DSL

  step "I have had a number of conversations over a period of time" do
    @user = users(:alice)
    @search_text = "quarterly projections"
    @search_user = users(:charlie)
  end
end
