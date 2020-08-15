# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'categories', type: :request do
  include_context 'with a logged in user'

  describe 'creating' do
    it 'sets the sort order to one more than the max' do
      FactoryBot.create(:category, user: user, sort_order: 1)
      FactoryBot.create(:category, user: user, sort_order: 3)

      body = {
        data: {
          type: 'categories',
          attributes: { name: 'New Category' },
        },
      }
      post '/categories', headers: headers, params: body.to_json

      expect(response.status).to eq(201)

      response_body = JSON.parse(response.body)
      expect(response_body['data']['attributes']['sort-order']).to eq(4)
    end

    it 'sets the sort order of the first category to 1' do
      body = {
        data: {
          type: 'categories',
          attributes: { name: 'New Category' },
        },
      }
      post '/categories', headers: headers, params: body.to_json

      puts response.body
      expect(response.status).to eq(201)

      response_body = JSON.parse(response.body)
      expect(response_body['data']['attributes']['sort-order']).to eq(1)
    end
  end
end
