# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'todos', type: :request do
  include_context 'with a logged in user'

  it 'allows retrieving all todos' do
    todo = FactoryBot.create(:todo, user: user)

    get '/todos', headers: headers

    expect(response.status).to eq(200)

    response_body = JSON.parse(response.body)
    expect(response_body['data'].count).to eq(1)
    expect(response_body['data'][0]['attributes']['name']).to eq(todo.name)
  end
end
