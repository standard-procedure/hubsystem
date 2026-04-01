# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class
  include ActionView::RecordIdentifier
  include HasAttachments
  include HasTypeChecks
  include Literal::Types
end
