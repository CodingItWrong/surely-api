# frozen_string_literal: true
class CategoryResource < ApplicationResource
  attributes :name, :sort_order
  has_one :user
  has_many :todos

  before_create { _model.user = current_user }

  def self.creatable_fields(context)
    super + %i[id] - %i[user created_at updated_at]
  end

  def self.updatable_fields(context)
    super - %i[user created_at updated_at]
  end

  def self.records(options = {})
    user = current_user(options)
    user.categories
  end
end
