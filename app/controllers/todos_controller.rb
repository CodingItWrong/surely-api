# frozen_string_literal: true
class TodosController < ApplicationController
  before_action :doorkeeper_authorize!

  def index
    if is_available_or_tomorrow?
      todos = Todo.status(:available).or(Todo.status(:tomorrow))
      headers['Content-Type'] = 'application/vnd.api+json'
      render json: serialize_todos(todos)
    else
      super
    end
  end

  private

  def is_available_or_tomorrow?
    params[:filter] && params[:filter][:status] == 'available,tomorrow' && params[:include] == 'category'
  end

  def serialize_todos(todos)
    {
      data: todos.map { |r| serialize_todo(r) },
      included: included_categories(todos)
                  .map { |r| serialize_category(r) },
      meta: {'page-count': 1},
    }
  end

  def included_categories(todos)
    todos.map(&:category).compact.uniq
  end

  def serialize_todo(r)
    {
      type: 'todos',
      id: r.id,
      attributes: serialize_attributes(
        record: r,
        attributes: %i(name notes created_at updated_at deferred_at deferred_until),
      ),
      relationships: {
        category: {
          data: r.category && {type: 'categories', id: r.category.id},
        },
      },
    }
  end

  def serialize_category(r)
    {
      type: 'categories',
      id: r.id,
      attributes: serialize_attributes(
        record: r,
        attributes: %i(name sort_order),
      ),
    }
  end

  def serialize_attributes(record:, attributes:)
    attributes.to_h { |a|
      value = record.public_send(a)
      value.respond_to?(:iso8601) && value = value.iso8601(3)
      [a.to_s.dasherize, value]
    }
  end
end
