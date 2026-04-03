# frozen_string_literal: true

class Components::Paginate < Components::Base
  include Phlex::Rails::Helpers::LinkTo
  include Kaminari::Helpers::HelperMethods

  prop :records, _Any
  prop :params, _Any, reader: :public

  def view_template
    Row justify: "end", gap: 4 do
      link_to_previous_page @records, "←", class: %w[btn-secondary]
      link_to_next_page @records, "→", class: %w[btn-secondary]
    end
  end
end
