# frozen_string_literal: true

Rails.application.routes.draw do
  use_doorkeeper
  resources :users, only: [:create]
  jsonapi_resources :todos
  jsonapi_resources :categories
end
