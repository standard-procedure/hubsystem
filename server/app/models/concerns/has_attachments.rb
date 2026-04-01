# frozen_string_literal: true

# Adds standard sizes to active storage attachments for any attachments that are resizable
# use `has_attachments` in place of `has_many_attached` and `has_attachment` in place of `has_one_attached`
module HasAttachments
  extend ActiveSupport::Concern

  class_methods do
    def has_attachments(*)
      has_many_attached(*) { |a| set_variants_for(a) }
    end

    def validate_images_for(attachments)
      method_name = :"validate_#{attachments}_are_images"
      define_method method_name do
        errors.add attachments, :invalid if send(attachments).any? { |a| !a.blob.image? }
      end
      validate method_name, if: -> { send(attachments).attached? }
    end

    def has_attachment(*)
      has_one_attached(*) { |a| set_variants_for(a) }
    end

    def validate_image_for(attachment)
      method_name = :"validate_#{attachment}_is_image"
      define_method method_name do
        errors.add attachment, :invalid unless send(attachment).blob.image?
      end
      validate method_name, if: -> { send(attachment).attached? }
    end

    def set_variants_for attachment
      attachment.variant :xxs, resize_to_limit: [32, 32]
      attachment.variant :xs, resize_to_limit: [64, 64]
      attachment.variant :sm, resize_to_limit: [128, 128]
      attachment.variant :md, resize_to_limit: [256, 256]
      attachment.variant :lg, resize_to_limit: [512, 512]
      attachment.variant :xl, resize_to_limit: [1024, 1024]
      attachment.variant :xxl, resize_to_limit: [4096, 4096]
    end
  end
end
