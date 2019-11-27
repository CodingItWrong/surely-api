# frozen_string_literal: true
class TodoResource < ApplicationResource
  attribute :name
  has_one :user

  before_create { _model.user = current_user }

  def self.creatable_fields(context)
    super + %i[id] - %i[user]
  end

  def self.updatable_fields(context)
    super - %i[user]
  end

  def self.records(options = {})
    user = current_user(options)
    user.todos
  end
end
