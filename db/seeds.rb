# frozen_string_literal: true
user = User.create!(email: 'example@example.com', password: 'password')

user.todos.create!(name: 'Buy bread')
user.todos.create!(name: 'Buy milk')
user.todos.create!(name: 'Buy eggs')
