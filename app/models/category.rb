# frozen_string_literal: true
class Category < ApplicationRecord
  belongs_to :user
  has_many :todos
end
