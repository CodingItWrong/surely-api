# frozen_string_literal: true
class TodosController < ApplicationController
  before_action :doorkeeper_authorize!
end
