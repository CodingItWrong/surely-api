# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'todos', type: :request do
  include_context 'with a logged in user'

  it 'allows retrieving all todos' do
    todos = FactoryBot.create_list(:todo, 3, user: user)

    get '/todos?sort=name', headers: headers

    expect(response.status).to eq(200)

    response_body = JSON.parse(response.body)
    expect(response_body['data'].count).to eq(3)
    expect(response_body['data'][0]['attributes']['name']).to eq(todos[0].name)
  end
end
