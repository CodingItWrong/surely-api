# frozen_string_literal: true
class UserResource < ApplicationResource
  attributes :email, :password
  has_many :todos
end
