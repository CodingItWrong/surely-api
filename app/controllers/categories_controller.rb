# frozen_string_literal: true
class CategoriesController < ApplicationController
  before_action :doorkeeper_authorize!
end
