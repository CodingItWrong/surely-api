# frozen_string_literal: true
class TodoResource < ApplicationResource
  attributes :name, :notes, :created_at, :updated_at, :deleted_at, :completed_at, :deferred_at, :deferred_until
  has_one :user
  has_one :category

  before_create { _model.user = current_user }

  def self.creatable_fields(context)
    super + %i[id] - %i[user created_at updated_at]
  end

  def self.updatable_fields(context)
    super - %i[user created_at updated_at]
  end

  def self.records(options = {})
    user = current_user(options)
    user.todos
  end

  filter :status, apply: ->(records, values, _options) {
    relation = records.status(values.first)

    if values.length > 1
      relation = values.drop(1).inject(relation) { |rel, value|
        rel.or(records.status(value))
      }
    end

    relation
  }

  filter :completed_at, apply: ->(records, values, _options) {
    if values == ['null']
      records.where(completed_at: nil)
    else
      'HIHIHI'
    end
  }

  filter :deleted_at, apply: ->(records, values, _options) {
    if values == ['null']
      records.where(deleted_at: nil)
    else
      'HIHIHI'
    end
  }

  filter :search, apply: ->(records, value, _options) {
    records.where('name ILIKE ?', "%#{value[0]}%")
  }
end
