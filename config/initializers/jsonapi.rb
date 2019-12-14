# frozen_string_literal: true
JSONAPI.configure do |config|
  config.resource_key_type = :uuid
  config.json_key_format = :camelized_key
end
