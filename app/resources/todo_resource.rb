# frozen_string_literal: true
class TodoResource < JSONAPI::Resource
  attribute :name

  def self.creatable_fields(context)
    super + %i[id]
  end
end
