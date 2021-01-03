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

  it 'allows sorting todos' do
    older_todo = FactoryBot.create(:todo, user: user, completed_at: 2.days.ago)
    newer_todo = FactoryBot.create(:todo, user: user, completed_at: 1.day.ago)

    get '/todos?sort=-completedAt', headers: headers

    expect(response.status).to eq(200)
    response_body = JSON.parse(response.body)

    expect(response_body['data'].count).to eq(2)
    expect(response_body['data'][0]['attributes']['name']).to eq(newer_todo.name)
    expect(response_body['data'][1]['attributes']['name']).to eq(older_todo.name)
  end
end
