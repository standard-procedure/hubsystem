# frozen_string_literal: true

module HasTags
  extend ActiveSupport::Concern

  included do
    scope :tagged_with, ->(tag) { where("? = ANY(tags)", tag) }
  end
end
