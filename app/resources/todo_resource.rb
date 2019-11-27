# frozen_string_literal: true
class TodoResource < JSONAPI::Resource
  attribute :name
  has_one :user

  def self.creatable_fields(context)
    super + %i[id]
  end
end
