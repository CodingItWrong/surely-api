# frozen_string_literal: true

require "optional_paged_paginator"

JSONAPI.configure do |config|
  config.resource_key_type = :uuid

  # config.default_paginator = :paged
  config.default_paginator = :optional_paged
  config.top_level_meta_include_page_count = true
  config.top_level_meta_page_count_key = :page_count
end
