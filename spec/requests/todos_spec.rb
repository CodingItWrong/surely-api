# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'todos', type: :request do
  include_context 'with a logged in user'

  JSON_API_CONTENT_TYPE = 'application/vnd.api+json'

  def time_string(time)
    time.iso8601(3)
  end

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

  describe 'request for available and tomorrow todos' do
    let(:body) { JSON.parse(response.body) }

    describe 'filtering' do
      let!(:available_todo) {
        FactoryBot.create(
          :todo,
          :available,
          user: user,
        )
      }
      let!(:tomorrow_todo) {
        FactoryBot.create(
          :todo,
          :tomorrow,
          user: user,
        )
      }
      let!(:future_todo) {
        FactoryBot.create(
          :todo,
          :future,
          user: user,
        )
      }
      let!(:completed_todo) {
        FactoryBot.create(
          :todo,
          :completed,
          user: user,
        )
      }
      let!(:deleted_todo) {
        FactoryBot.create(
          :todo,
          :deleted,
          user: user,
        )
      }

      before(:each) do
        get '/todos?filter[status]=available,tomorrow&include=category', headers: headers
      end

      it 'includes available todo' do
        expect(body['data']).to include a_hash_including(
          'type' => 'todos',
          'id' => available_todo.id,
        )
      end

      it 'includes tomorrow todo' do
        expect(body['data']).to include a_hash_including(
          'type' => 'todos',
          'id' => tomorrow_todo.id,
        )
      end

      it 'does not include future todo' do
        expect(body['data']).not_to include a_hash_including(
          'type' => 'todos',
          'id' => future_todo.id,
        )
      end

      it 'does not include completed todo' do
        expect(body['data']).not_to include a_hash_including(
          'type' => 'todos',
          'id' => completed_todo.id,
        )
      end

      it 'does not include deleted todo' do
        expect(body['data']).not_to include a_hash_including(
          'type' => 'todos',
          'id' => deleted_todo.id,
        )
      end
    end

    describe 'contents' do
      let!(:todo) {
        FactoryBot.create(
          :todo,
          :available,
          user: user,
        )
      }

      before(:each) do
        get '/todos?filter[status]=available,tomorrow&include=category', headers: headers
      end

      it 'has success status' do
        expect(response.status).to eq(200)
      end

      it 'has json:api content type' do
        expect(response.headers['Content-Type']).to eq(JSON_API_CONTENT_TYPE)
      end

      it 'includes all todo attributes' do
        expect(body['data'][0]['attributes']).to include(
          'name' => todo.name,
          'notes' => todo.notes,
          'created-at' => time_string(todo.created_at),
          'updated-at' => time_string(todo.updated_at),
          'deferred-at' => time_string(todo.deferred_at),
          'deferred-until' => time_string(todo.deferred_until),
        )
      end

      it 'includes page count' do
        expect(body['meta']).to eq({'page-count' => 1})
      end
    end

    describe 'category relationship' do
      let!(:category) { FactoryBot.create(:category, user: user) }
      let!(:category_todo_1) {
        FactoryBot.create(
          :todo,
          user: user,
          category: category,
        )
      }
      let!(:category_todo_2) {
        FactoryBot.create(
          :todo,
          user: user,
          category: category,
        )
      }
      let!(:no_category_todo) {
        FactoryBot.create(
          :todo,
          user: user,
        )
      }

      before(:each) do
        get '/todos?filter[status]=available,tomorrow&include=category', headers: headers
      end

      it 'includes category relationship when present' do
        record = body['data'].find { |r|
          r['id'] == category_todo_1.id
        }

        expect(record['relationships']).to include(
          'category' => a_hash_including(
            'data' => {
              'type' => 'categories',
              'id' => category.id,
            }
          )
        )
      end

      it 'includes nil for category relationship when absent' do
        record = body['data'].find { |r|
          r['id'] == no_category_todo.id
        }

        expect(record['relationships']).to include(
          'category' => a_hash_including(
            'data' => nil
          )
        )
      end

      it 'includes category' do
        expect(body['included']).to match_array([
          a_hash_including({
            'type' => 'categories',
            'id' => category.id,
            'attributes' => a_hash_including({
              'name' => category.name,
              'sort-order' => category.sort_order,
            }),
          }),
        ])
      end
    end
  end
end
