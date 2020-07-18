# frozen_string_literal: true

class NullPaginator < JSONAPI::Paginator
  def initialize(params)
  end

  def apply(relation, order_options)
    relation
  end

  def links_page_params(_options = {})
    {}
  end
end
