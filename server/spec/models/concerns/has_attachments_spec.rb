# frozen_string_literal: true

require "rails_helper"

RSpec.describe HasAttachments do
  # has_attachment (singular) tested through User (photo)
  # has_attachments (plural) tested through Conversation::Message (attachments)

  describe "has_attachment" do
    it "creates a has_one_attached reflection" do
      expect(User.reflect_on_attachment(:photo)).to be_present
    end

    it "registers the standard image variants" do
      variants = User.attachment_reflections["photo"].named_variants.keys
      expect(variants).to include(:xxs, :xs, :sm, :md, :lg, :xl, :xxl)
    end
  end

  describe "has_attachments" do
    it "creates a has_many_attached reflection" do
      expect(Conversation::Message.reflect_on_attachment(:attachments)).to be_present
    end

    it "registers the standard image variants" do
      variants = Conversation::Message.attachment_reflections["attachments"].named_variants.keys
      expect(variants).to include(:xxs, :xs, :sm, :md, :lg, :xl, :xxl)
    end
  end

  describe "validate_image_for" do
    it "registers a callback on the model" do
      callbacks = User._validate_callbacks.map(&:filter)
      expect(callbacks).to include(:validate_photo_is_image)
    end
  end
end
