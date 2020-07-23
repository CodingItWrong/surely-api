# frozen_string_literal: true
Rails.application.routes.draw do
  use_doorkeeper
  jsonapi_resources :users, only: %w[create]
  jsonapi_resources :todos
end
