# frozen_string_literal: true

Rails.application.routes.draw do
  use_doorkeeper
  resources :users, only: [:create]
  resources :todos, except: [:new, :edit]
  resources :categories
end
