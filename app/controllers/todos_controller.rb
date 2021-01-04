# frozen_string_literal: true
class TodosController < ApplicationController
  before_action :doorkeeper_authorize!

  def index
    if is_available_or_tomorrow?
      todos = Todo.status(:available).or(Todo.status(:tomorrow))
      response = {
        data: todos.map { |r|
          {
            type: 'todos',
            id: r.id,
            attributes: {
              name: r.name,
              notes: r.notes,
              'created-at' => time_string(r.created_at),
              'updated-at' => time_string(r.updated_at),
              'deferred-at' => time_string(r.deferred_at),
              'deferred-until' => time_string(r.deferred_until),
            },
            relationships: {
              category: {
                data: r.category && {type: 'categories', id: r.category.id},
              },
            },
          }
        },
        included: todos.map(&:category)
                       .compact
                       .uniq
                       .map { |r|
                         {
                           type: 'categories',
                           id: r.id,
                           attributes: {
                             name: r.name,
                             'sort-order': r.sort_order,
                           },
                         }
                       },
        meta: {'page-count': 1},
      }
      headers['Content-Type'] = 'application/vnd.api+json'
      render json: response
    else
      super
    end
  end

  private

  def is_available_or_tomorrow?
    params[:filter] && params[:filter][:status] == 'available,tomorrow' && params[:include] == 'category'
  end

  def time_string(time)
    time&.iso8601(3)
  end
end
