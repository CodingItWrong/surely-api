# frozen_string_literal: true
class Todo < ApplicationRecord
  belongs_to :user
  belongs_to :category, required: false

  scope :status, ->(status) {
    case status.to_sym
    when :available
      status(:open).where('deferred_until IS NULL OR deferred_until <= NOW()')
    when :completed
      where.not(completed_at: nil)
    when :deleted
      where.not(deleted_at: nil)
    when :future
      status(:open).where('deferred_until > NOW()')
    when :open
      where('completed_at IS NULL AND deleted_at IS NULL')
    when :tomorrow
      status(:future).where('deferred_until < ?', 1.day.from_now)
    end
  }
end
