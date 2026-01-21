# frozen_string_literal: true

class TodosController < JsonapiResourcesController
  before_action :doorkeeper_authorize!
end
