# frozen_string_literal: true

class CategoriesController < JsonapiResourcesController
  before_action :doorkeeper_authorize!
end
