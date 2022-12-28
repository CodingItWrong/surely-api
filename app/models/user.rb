# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password
  has_many :todos
  has_many :categories

  validates :email, presence: true, uniqueness: true
end
