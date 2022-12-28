# frozen_string_literal: true

class Category < ApplicationRecord
  belongs_to :user
  has_many :todos

  before_create :set_default_values

  private

  def set_default_values
    max_sort_order = user.categories.maximum(:sort_order) || 0
    self.sort_order ||= max_sort_order + 1
  end
end
