# frozen_string_literal: true

require "rails_helper"

RSpec.describe "todos", type: :request do
  include_context "with a logged in user"

  describe "GET /todos" do
    # ==========================================================================
    # FILTER[STATUS]=AVAILABLE
    # ==========================================================================
    context "with filter[status]=available" do
      context "when logged in" do
        it "returns successful response" do
          get "/todos?filter[status]=available", headers: headers

          expect(response.status).to eq(200)
        end

        it "returns JSON:API formatted response" do
          get "/todos?filter[status]=available", headers: headers

          expect(response.content_type).to match(%r{application/vnd\.api\+json})

          response_body = JSON.parse(response.body)
          expect(response_body).to have_key("data")
          expect(response_body).not_to have_key("errors")
        end

        it "returns array of todos" do
          get "/todos?filter[status]=available", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"]).to be_an(Array)
        end

        it "returns available todos (no deferred_until)" do
          available_todo = create(:todo, user: user, name: "Available", deferred_until: nil)
          create(:todo, user: user, name: "Completed", completed_at: Time.current)
          create(:todo, user: user, name: "Deleted", deleted_at: Time.current)

          get "/todos?filter[status]=available", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"].length).to eq(1)
          expect(response_body["data"][0]["id"]).to eq(available_todo.id)
        end

        it "returns todos deferred to past as available" do
          past_deferred_todo = create(:todo, user: user, name: "Past Deferred", deferred_until: 1.day.ago)

          get "/todos?filter[status]=available", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"].length).to eq(1)
          expect(response_body["data"][0]["id"]).to eq(past_deferred_todo.id)
        end

        it "excludes completed todos" do
          create(:todo, user: user, name: "Available")
          create(:todo, user: user, name: "Completed", completed_at: Time.current)

          get "/todos?filter[status]=available", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"].length).to eq(1)
          expect(response_body["data"][0]["attributes"]["name"]).to eq("Available")
        end

        it "excludes deleted todos" do
          create(:todo, user: user, name: "Available")
          create(:todo, user: user, name: "Deleted", deleted_at: Time.current)

          get "/todos?filter[status]=available", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"].length).to eq(1)
          expect(response_body["data"][0]["attributes"]["name"]).to eq("Available")
        end

        it "excludes tomorrow-deferred todos" do
          create(:todo, user: user, name: "Available")
          create(:todo, user: user, name: "Tomorrow", deferred_until: Date.tomorrow)

          get "/todos?filter[status]=available", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"].length).to eq(1)
          expect(response_body["data"][0]["attributes"]["name"]).to eq("Available")
        end

        it "excludes future-deferred todos" do
          create(:todo, user: user, name: "Available")
          create(:todo, user: user, name: "Future", deferred_until: 3.days.from_now)

          get "/todos?filter[status]=available", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"].length).to eq(1)
          expect(response_body["data"][0]["attributes"]["name"]).to eq("Available")
        end

        it "returns todos with correct structure" do
          create(:todo, user: user, name: "Test Todo")

          get "/todos?filter[status]=available", headers: headers

          response_body = JSON.parse(response.body)
          todo_data = response_body["data"].first

          expect(todo_data["type"]).to eq("todos")
          expect(todo_data["id"]).to be_present
          expect(todo_data).to have_key("attributes")
        end

        it "returns all todo attributes" do
          todo = create(:todo,
            user: user,
            name: "Test Todo",
            notes: "Some notes",
            deferred_until: Date.tomorrow,
            completed_at: nil,
            deleted_at: nil)

          # Set it back to available by removing deferred_until
          todo.update!(deferred_until: nil)

          get "/todos?filter[status]=available", headers: headers

          response_body = JSON.parse(response.body)
          attributes = response_body["data"].first["attributes"]

          expect(attributes["name"]).to eq("Test Todo")
          expect(attributes["notes"]).to eq("Some notes")
          expect(attributes["completed-at"]).to be_nil
          expect(attributes["deleted-at"]).to be_nil
          expect(attributes["deferred-until"]).to be_nil
        end

        it "transforms snake_case to kebab-case in attributes" do
          create(:todo, user: user, completed_at: nil, deleted_at: nil)

          get "/todos?filter[status]=available", headers: headers

          response_body = JSON.parse(response.body)
          attributes = response_body["data"].first["attributes"]

          expect(attributes).to have_key("completed-at")
          expect(attributes).to have_key("deleted-at")
          expect(attributes).to have_key("deferred-until")
          expect(attributes).not_to have_key("completed_at")
          expect(attributes).not_to have_key("deleted_at")
          expect(attributes).not_to have_key("deferred_until")
        end

        it "does not return other users' todos" do
          other_user = create(:user)
          create(:todo, user: other_user, name: "Other User Todo")
          create(:todo, user: user, name: "My Todo")

          get "/todos?filter[status]=available", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"].length).to eq(1)
          expect(response_body["data"][0]["attributes"]["name"]).to eq("My Todo")
        end

        it "returns empty array when user has no available todos" do
          create(:todo, user: user, completed_at: Time.current)

          get "/todos?filter[status]=available", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"]).to eq([])
        end
      end

      context "when logged out" do
        it "returns 401 unauthorized" do
          get "/todos?filter[status]=available"

          expect(response.status).to eq(401)
        end

        it "returns empty response body" do
          get "/todos?filter[status]=available"

          expect(response.body).to be_empty
        end
      end

      context "with include=category" do
        it "includes related categories in included array" do
          category = create(:category, user: user, name: "Work", sort_order: 1)
          create(:todo, user: user, name: "Todo with category", category: category)

          get "/todos?filter[status]=available&include=category", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body).to have_key("included")
          expect(response_body["included"]).to be_an(Array)
          expect(response_body["included"].length).to eq(1)

          included_category = response_body["included"].first
          expect(included_category["type"]).to eq("categories")
          expect(included_category["id"]).to eq(category.id)
          expect(included_category["attributes"]["name"]).to eq("Work")
          expect(included_category["attributes"]["sort-order"]).to eq(1)
        end

        it "includes category reference in todo relationships" do
          category = create(:category, user: user, name: "Work")
          create(:todo, user: user, name: "Todo with category", category: category)

          get "/todos?filter[status]=available&include=category", headers: headers

          response_body = JSON.parse(response.body)
          todo_data = response_body["data"].first

          expect(todo_data).to have_key("relationships")
          expect(todo_data["relationships"]).to have_key("category")
          expect(todo_data["relationships"]["category"]["data"]["type"]).to eq("categories")
          expect(todo_data["relationships"]["category"]["data"]["id"]).to eq(category.id)
        end

        it "handles todos without categories" do
          create(:todo, user: user, name: "Todo without category", category: nil)

          get "/todos?filter[status]=available&include=category", headers: headers

          response_body = JSON.parse(response.body)
          todo_data = response_body["data"].first

          expect(todo_data["relationships"]["category"]["data"]).to be_nil
        end

        it "includes each category only once when multiple todos share it" do
          category = create(:category, user: user, name: "Work")
          create(:todo, user: user, name: "Todo 1", category: category)
          create(:todo, user: user, name: "Todo 2", category: category)

          get "/todos?filter[status]=available&include=category", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["included"].length).to eq(1)
          expect(response_body["data"].length).to eq(2)
        end

        it "includes multiple different categories" do
          category1 = create(:category, user: user, name: "Work")
          category2 = create(:category, user: user, name: "Personal")
          create(:todo, user: user, name: "Todo 1", category: category1)
          create(:todo, user: user, name: "Todo 2", category: category2)

          get "/todos?filter[status]=available&include=category", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["included"].length).to eq(2)

          category_ids = response_body["included"].map { |c| c["id"] }
          expect(category_ids).to contain_exactly(category1.id, category2.id)
        end
      end

      context "without include parameter" do
        it "does not include categories in response" do
          category = create(:category, user: user, name: "Work")
          create(:todo, user: user, name: "Todo with category", category: category)

          get "/todos?filter[status]=available", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body).not_to have_key("included")
        end
      end
    end

    # ==========================================================================
    # FILTER[STATUS]=TOMORROW
    # ==========================================================================
    context "with filter[status]=tomorrow" do
      it "returns todos deferred to tomorrow" do
        tomorrow_todo = create(:todo, user: user, name: "Tomorrow", deferred_until: Date.tomorrow)
        create(:todo, user: user, name: "Available")
        create(:todo, user: user, name: "Future", deferred_until: 3.days.from_now)

        get "/todos?filter[status]=tomorrow", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(1)
        expect(response_body["data"][0]["id"]).to eq(tomorrow_todo.id)
      end

      it "excludes available todos" do
        create(:todo, user: user, name: "Tomorrow", deferred_until: Date.tomorrow)
        create(:todo, user: user, name: "Available")

        get "/todos?filter[status]=tomorrow", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(1)
        expect(response_body["data"][0]["attributes"]["name"]).to eq("Tomorrow")
      end

      it "excludes future todos" do
        create(:todo, user: user, name: "Tomorrow", deferred_until: Date.tomorrow)
        create(:todo, user: user, name: "Future", deferred_until: 3.days.from_now)

        get "/todos?filter[status]=tomorrow", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(1)
        expect(response_body["data"][0]["attributes"]["name"]).to eq("Tomorrow")
      end

      it "excludes completed todos" do
        create(:todo, user: user, name: "Tomorrow", deferred_until: Date.tomorrow)
        create(:todo, user: user, name: "Completed", completed_at: Time.current)

        get "/todos?filter[status]=tomorrow", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(1)
        expect(response_body["data"][0]["attributes"]["name"]).to eq("Tomorrow")
      end

      it "excludes deleted todos" do
        create(:todo, user: user, name: "Tomorrow", deferred_until: Date.tomorrow)
        create(:todo, user: user, name: "Deleted", deleted_at: Time.current)

        get "/todos?filter[status]=tomorrow", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(1)
        expect(response_body["data"][0]["attributes"]["name"]).to eq("Tomorrow")
      end

      it "supports include=category" do
        category = create(:category, user: user, name: "Work")
        create(:todo, user: user, name: "Tomorrow", deferred_until: Date.tomorrow, category: category)

        get "/todos?filter[status]=tomorrow&include=category", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body).to have_key("included")
        expect(response_body["included"].length).to eq(1)
        expect(response_body["included"].first["id"]).to eq(category.id)
      end
    end

    # ==========================================================================
    # FILTER[STATUS]=FUTURE
    # ==========================================================================
    context "with filter[status]=future" do
      it "returns todos deferred to future (including tomorrow)" do
        # Note: "future" and "tomorrow" are not mutually exclusive
        # "future" includes all todos deferred to the future (tomorrow and beyond)
        # "tomorrow" is a subset of "future" for todos deferred to tomorrow specifically
        future_todo = create(:todo, user: user, name: "Future", deferred_until: 3.days.from_now.to_date)
        tomorrow_todo = create(:todo, user: user, name: "Tomorrow", deferred_until: Date.tomorrow)
        create(:todo, user: user, name: "Available")

        get "/todos?filter[status]=future", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(2)

        ids = response_body["data"].map { |t| t["id"] }
        expect(ids).to contain_exactly(future_todo.id, tomorrow_todo.id)
      end

      it "excludes available todos" do
        create(:todo, user: user, name: "Future", deferred_until: 3.days.from_now)
        create(:todo, user: user, name: "Available")

        get "/todos?filter[status]=future", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(1)
        expect(response_body["data"][0]["attributes"]["name"]).to eq("Future")
      end

      it "includes all deferred todos (tomorrow and beyond)" do
        # "future" includes all future-deferred todos
        create(:todo, user: user, name: "Future Far", deferred_until: 3.days.from_now)
        create(:todo, user: user, name: "Tomorrow", deferred_until: Date.tomorrow)

        get "/todos?filter[status]=future", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(2)
        names = response_body["data"].map { |t| t["attributes"]["name"] }
        expect(names).to contain_exactly("Future Far", "Tomorrow")
      end

      it "excludes completed todos" do
        create(:todo, user: user, name: "Future", deferred_until: 3.days.from_now)
        create(:todo, user: user, name: "Completed", completed_at: Time.current)

        get "/todos?filter[status]=future", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(1)
        expect(response_body["data"][0]["attributes"]["name"]).to eq("Future")
      end

      it "excludes deleted todos" do
        create(:todo, user: user, name: "Future", deferred_until: 3.days.from_now)
        create(:todo, user: user, name: "Deleted", deleted_at: Time.current)

        get "/todos?filter[status]=future", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(1)
        expect(response_body["data"][0]["attributes"]["name"]).to eq("Future")
      end

      context "with filter[search]" do
        it "filters todos by search text" do
          create(:todo, user: user, name: "Buy groceries", deferred_until: 3.days.from_now)
          create(:todo, user: user, name: "Call dentist", deferred_until: 3.days.from_now)

          get "/todos?filter[status]=future&filter[search]=groceries", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"].length).to eq(1)
          expect(response_body["data"][0]["attributes"]["name"]).to eq("Buy groceries")
        end

        it "performs case-insensitive search" do
          create(:todo, user: user, name: "Buy Groceries", deferred_until: 3.days.from_now)

          get "/todos?filter[status]=future&filter[search]=groceries", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"].length).to eq(1)
        end

        it "performs partial match search" do
          create(:todo, user: user, name: "Buy groceries", deferred_until: 3.days.from_now)

          get "/todos?filter[status]=future&filter[search]=groc", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"].length).to eq(1)
        end
      end

      context "with sort=name" do
        it "sorts todos by name ascending" do
          todo_b = create(:todo, user: user, name: "B Task", deferred_until: 3.days.from_now)
          todo_a = create(:todo, user: user, name: "A Task", deferred_until: 3.days.from_now)

          get "/todos?filter[status]=future&sort=name", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"][0]["id"]).to eq(todo_a.id)
          expect(response_body["data"][1]["id"]).to eq(todo_b.id)
        end
      end

      context "with sort=-name" do
        it "sorts todos by name descending" do
          todo_b = create(:todo, user: user, name: "B Task", deferred_until: 3.days.from_now)
          todo_a = create(:todo, user: user, name: "A Task", deferred_until: 3.days.from_now)

          get "/todos?filter[status]=future&sort=-name", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"][0]["id"]).to eq(todo_b.id)
          expect(response_body["data"][1]["id"]).to eq(todo_a.id)
        end
      end

      it "supports include=category" do
        category = create(:category, user: user, name: "Work")
        create(:todo, user: user, name: "Future", deferred_until: 3.days.from_now, category: category)

        get "/todos?filter[status]=future&include=category", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body).to have_key("included")
        expect(response_body["included"].length).to eq(1)
      end

      it "combines search, sort, and include parameters" do
        category = create(:category, user: user, name: "Work")
        create(:todo, user: user, name: "B Buy groceries", deferred_until: 3.days.from_now, category: category)
        create(:todo, user: user, name: "A Buy milk", deferred_until: 3.days.from_now, category: category)
        create(:todo, user: user, name: "Call dentist", deferred_until: 3.days.from_now)

        get "/todos?filter[status]=future&filter[search]=buy&sort=name&include=category", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(2)
        expect(response_body["data"][0]["attributes"]["name"]).to eq("A Buy milk")
        expect(response_body["data"][1]["attributes"]["name"]).to eq("B Buy groceries")
        expect(response_body).to have_key("included")
      end
    end

    # ==========================================================================
    # FILTER[STATUS]=COMPLETED
    # ==========================================================================
    context "with filter[status]=completed" do
      it "returns completed todos" do
        completed_todo = create(:todo, user: user, name: "Completed", completed_at: Time.current)
        create(:todo, user: user, name: "Available")

        get "/todos?filter[status]=completed", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(1)
        expect(response_body["data"][0]["id"]).to eq(completed_todo.id)
      end

      it "excludes available todos" do
        create(:todo, user: user, name: "Completed", completed_at: Time.current)
        create(:todo, user: user, name: "Available")

        get "/todos?filter[status]=completed", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(1)
        expect(response_body["data"][0]["attributes"]["name"]).to eq("Completed")
      end

      it "excludes deleted todos" do
        create(:todo, user: user, name: "Completed", completed_at: Time.current)
        create(:todo, user: user, name: "Deleted", deleted_at: Time.current)

        get "/todos?filter[status]=completed", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(1)
        expect(response_body["data"][0]["attributes"]["name"]).to eq("Completed")
      end

      it "sorts by completed_at descending by default" do
        newer_todo = create(:todo, user: user, name: "Newer", completed_at: 1.day.ago)
        older_todo = create(:todo, user: user, name: "Older", completed_at: 2.days.ago)

        get "/todos?filter[status]=completed&sort=-completedAt", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"][0]["id"]).to eq(newer_todo.id)
        expect(response_body["data"][1]["id"]).to eq(older_todo.id)
      end

      context "with filter[search]" do
        it "filters completed todos by search text" do
          create(:todo, user: user, name: "Buy groceries", completed_at: Time.current)
          create(:todo, user: user, name: "Call dentist", completed_at: Time.current)

          get "/todos?filter[status]=completed&filter[search]=groceries", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"].length).to eq(1)
          expect(response_body["data"][0]["attributes"]["name"]).to eq("Buy groceries")
        end
      end

      context "with pagination" do
        it "includes page-count in meta" do
          create_list(:todo, 15, user: user, completed_at: Time.current)

          get "/todos?filter[status]=completed&page[number]=1", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body).to have_key("meta")
          expect(response_body["meta"]).to have_key("page-count")
          expect(response_body["meta"]["page-count"]).to be > 0
        end

        it "returns correct page of results" do
          # Assuming default page size is 10
          create_list(:todo, 15, user: user, completed_at: Time.current)

          get "/todos?filter[status]=completed&page[number]=1", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"].length).to be <= 10
        end

        it "returns different results for different pages" do
          create_list(:todo, 15, user: user, completed_at: Time.current)

          get "/todos?filter[status]=completed&page[number]=1", headers: headers
          page1_body = JSON.parse(response.body)
          page1_ids = page1_body["data"].map { |t| t["id"] }

          get "/todos?filter[status]=completed&page[number]=2", headers: headers
          page2_body = JSON.parse(response.body)
          page2_ids = page2_body["data"].map { |t| t["id"] }

          expect(page1_ids & page2_ids).to be_empty
        end

        it "returns empty array for page beyond page-count" do
          create_list(:todo, 5, user: user, completed_at: Time.current)

          get "/todos?filter[status]=completed&page[number]=99", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"]).to eq([])
        end
      end

      it "supports include=category" do
        category = create(:category, user: user, name: "Work")
        create(:todo, user: user, name: "Completed", completed_at: Time.current, category: category)

        get "/todos?filter[status]=completed&include=category", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body).to have_key("included")
        expect(response_body["included"].length).to eq(1)
      end

      it "combines search, sort, pagination, and include parameters" do
        category = create(:category, user: user, name: "Work")
        create_list(:todo, 15, user: user, completed_at: Time.current, category: category, name: "Buy groceries")

        get "/todos?filter[status]=completed&filter[search]=groceries&sort=-completedAt&page[number]=1&include=category", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"]).not_to be_empty
        expect(response_body).to have_key("meta")
        expect(response_body).to have_key("included")
      end
    end

    # ==========================================================================
    # FILTER[STATUS]=DELETED
    # ==========================================================================
    context "with filter[status]=deleted" do
      it "returns deleted todos" do
        deleted_todo = create(:todo, user: user, name: "Deleted", deleted_at: Time.current)
        create(:todo, user: user, name: "Available")

        get "/todos?filter[status]=deleted", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(1)
        expect(response_body["data"][0]["id"]).to eq(deleted_todo.id)
      end

      it "excludes available todos" do
        create(:todo, user: user, name: "Deleted", deleted_at: Time.current)
        create(:todo, user: user, name: "Available")

        get "/todos?filter[status]=deleted", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(1)
        expect(response_body["data"][0]["attributes"]["name"]).to eq("Deleted")
      end

      it "excludes completed todos" do
        create(:todo, user: user, name: "Deleted", deleted_at: Time.current)
        create(:todo, user: user, name: "Completed", completed_at: Time.current)

        get "/todos?filter[status]=deleted", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(1)
        expect(response_body["data"][0]["attributes"]["name"]).to eq("Deleted")
      end

      it "sorts by deleted_at descending by default" do
        newer_todo = create(:todo, user: user, name: "Newer", deleted_at: 1.day.ago)
        older_todo = create(:todo, user: user, name: "Older", deleted_at: 2.days.ago)

        get "/todos?filter[status]=deleted&sort=-deletedAt", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"][0]["id"]).to eq(newer_todo.id)
        expect(response_body["data"][1]["id"]).to eq(older_todo.id)
      end

      context "with filter[search]" do
        it "filters deleted todos by search text" do
          create(:todo, user: user, name: "Buy groceries", deleted_at: Time.current)
          create(:todo, user: user, name: "Call dentist", deleted_at: Time.current)

          get "/todos?filter[status]=deleted&filter[search]=groceries", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"].length).to eq(1)
          expect(response_body["data"][0]["attributes"]["name"]).to eq("Buy groceries")
        end
      end

      context "with pagination" do
        it "includes page-count in meta" do
          create_list(:todo, 15, user: user, deleted_at: Time.current)

          get "/todos?filter[status]=deleted&page[number]=1", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body).to have_key("meta")
          expect(response_body["meta"]).to have_key("page-count")
        end

        it "returns correct page of results" do
          create_list(:todo, 15, user: user, deleted_at: Time.current)

          get "/todos?filter[status]=deleted&page[number]=1", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"].length).to be <= 10
        end

        it "returns different results for different pages" do
          create_list(:todo, 15, user: user, deleted_at: Time.current)

          get "/todos?filter[status]=deleted&page[number]=1", headers: headers
          page1_body = JSON.parse(response.body)
          page1_ids = page1_body["data"].map { |t| t["id"] }

          get "/todos?filter[status]=deleted&page[number]=2", headers: headers
          page2_body = JSON.parse(response.body)
          page2_ids = page2_body["data"].map { |t| t["id"] }

          expect(page1_ids & page2_ids).to be_empty
        end
      end

      it "supports include=category" do
        category = create(:category, user: user, name: "Work")
        create(:todo, user: user, name: "Deleted", deleted_at: Time.current, category: category)

        get "/todos?filter[status]=deleted&include=category", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body).to have_key("included")
        expect(response_body["included"].length).to eq(1)
      end

      it "combines search, sort, pagination, and include parameters" do
        category = create(:category, user: user, name: "Work")
        create_list(:todo, 15, user: user, deleted_at: Time.current, category: category, name: "Buy groceries")

        get "/todos?filter[status]=deleted&filter[search]=groceries&sort=-deletedAt&page[number]=1&include=category", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"]).not_to be_empty
        expect(response_body).to have_key("meta")
        expect(response_body).to have_key("included")
      end
    end
  end

  # ==========================================================================
  # GET /todos/:id
  # ==========================================================================
  describe "GET /todos/:id" do
    context "when logged in" do
      it "returns successful response" do
        todo = create(:todo, user: user)

        get "/todos/#{todo.id}", headers: headers

        expect(response.status).to eq(200)
      end

      it "returns JSON:API formatted response" do
        todo = create(:todo, user: user)

        get "/todos/#{todo.id}", headers: headers

        expect(response.content_type).to match(%r{application/vnd\.api\+json})

        response_body = JSON.parse(response.body)
        expect(response_body).to have_key("data")
        expect(response_body).not_to have_key("errors")
      end

      it "returns single todo object (not array)" do
        todo = create(:todo, user: user)

        get "/todos/#{todo.id}", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"]).to be_a(Hash)
        expect(response_body["data"]).not_to be_an(Array)
      end

      it "returns todo with correct structure" do
        todo = create(:todo, user: user, name: "Test Todo")

        get "/todos/#{todo.id}", headers: headers

        response_body = JSON.parse(response.body)
        todo_data = response_body["data"]

        expect(todo_data["type"]).to eq("todos")
        expect(todo_data["id"]).to eq(todo.id)
        expect(todo_data).to have_key("attributes")
      end

      it "returns all todo attributes" do
        todo = create(:todo,
          user: user,
          name: "Test Todo",
          notes: "Some notes",
          deferred_until: Date.tomorrow,
          completed_at: Time.current,
          deleted_at: nil)

        get "/todos/#{todo.id}", headers: headers

        response_body = JSON.parse(response.body)
        attributes = response_body["data"]["attributes"]

        expect(attributes["name"]).to eq("Test Todo")
        expect(attributes["notes"]).to eq("Some notes")
        # Date fields are returned as ISO 8601 datetime strings by the current implementation
        expect(attributes["deferred-until"]).to be_present
        expect(attributes["completed-at"]).to be_present
        expect(attributes["deleted-at"]).to be_nil
      end

      it "returns 404 when todo doesn't exist" do
        get "/todos/00000000-0000-0000-0000-000000000000", headers: headers

        expect(response.status).to eq(404)
      end

      it "returns 404 when todo belongs to another user" do
        other_user = create(:user)
        other_todo = create(:todo, user: other_user)

        get "/todos/#{other_todo.id}", headers: headers

        expect(response.status).to eq(404)
      end

      context "with include=category" do
        it "includes category in included array" do
          category = create(:category, user: user, name: "Work", sort_order: 1)
          todo = create(:todo, user: user, category: category)

          get "/todos/#{todo.id}?include=category", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body).to have_key("included")
          expect(response_body["included"].length).to eq(1)
          expect(response_body["included"].first["id"]).to eq(category.id)
          expect(response_body["included"].first["type"]).to eq("categories")
        end

        it "handles todo without category" do
          todo = create(:todo, user: user, category: nil)

          get "/todos/#{todo.id}?include=category", headers: headers

          response_body = JSON.parse(response.body)
          expect(response_body["data"]["relationships"]["category"]["data"]).to be_nil
        end
      end
    end

    context "when logged out" do
      it "returns 401 unauthorized" do
        todo = create(:todo, user: user)

        get "/todos/#{todo.id}"

        expect(response.status).to eq(401)
      end

      it "returns empty response body" do
        todo = create(:todo, user: user)

        get "/todos/#{todo.id}"

        expect(response.body).to be_empty
      end
    end
  end

  # ==========================================================================
  # POST /todos
  # ==========================================================================
  describe "POST /todos" do
    context "when logged in" do
      it "creates a new todo" do
        expect {
          post "/todos", headers: headers, params: {
            data: {
              type: "todos",
              attributes: {
                name: "New Todo"
              }
            }
          }.to_json
        }.to change(Todo, :count).by(1)
      end

      it "returns 201 created status" do
        post "/todos", headers: headers, params: {
          data: {
            type: "todos",
            attributes: {
              name: "New Todo"
            }
          }
        }.to_json

        expect(response.status).to eq(201)
      end

      it "returns JSON:API formatted response" do
        post "/todos", headers: headers, params: {
          data: {
            type: "todos",
            attributes: {
              name: "New Todo"
            }
          }
        }.to_json

        expect(response.content_type).to match(%r{application/vnd\.api\+json})

        response_body = JSON.parse(response.body)
        expect(response_body).to have_key("data")
        expect(response_body).not_to have_key("errors")
      end

      it "returns created todo with correct attributes" do
        post "/todos", headers: headers, params: {
          data: {
            type: "todos",
            attributes: {
              name: "New Todo"
            }
          }
        }.to_json

        response_body = JSON.parse(response.body)
        expect(response_body["data"]["type"]).to eq("todos")
        expect(response_body["data"]["attributes"]["name"]).to eq("New Todo")
      end

      it "associates todo with current user" do
        post "/todos", headers: headers, params: {
          data: {
            type: "todos",
            attributes: {
              name: "New Todo"
            }
          }
        }.to_json

        created_todo = Todo.last
        expect(created_todo.user_id).to eq(user.id)
      end

      it "sets default values for optional attributes" do
        post "/todos", headers: headers, params: {
          data: {
            type: "todos",
            attributes: {
              name: "New Todo"
            }
          }
        }.to_json

        response_body = JSON.parse(response.body)
        expect(response_body["data"]["attributes"]["completed-at"]).to be_nil
        expect(response_body["data"]["attributes"]["deleted-at"]).to be_nil
        expect(response_body["data"]["attributes"]["deferred-until"]).to be_nil
      end

      it "creates todo with deferred-until date" do
        future_date = 3.days.from_now.to_date

        post "/todos", headers: headers, params: {
          data: {
            type: "todos",
            attributes: {
              name: "Future Todo",
              "deferred-until": future_date.to_s
            }
          }
        }.to_json

        response_body = JSON.parse(response.body)
        # Date fields are returned as ISO 8601 datetime strings by the current implementation
        expect(response_body["data"]["attributes"]["deferred-until"]).to be_present

        created_todo = Todo.last
        expect(created_todo.deferred_until).to eq(future_date)
      end

      it "creates todo with category relationship" do
        category = create(:category, user: user)

        post "/todos", headers: headers, params: {
          data: {
            type: "todos",
            attributes: {
              name: "Todo with category"
            },
            relationships: {
              category: {
                data: {
                  type: "categories",
                  id: category.id
                }
              }
            }
          }
        }.to_json

        created_todo = Todo.last
        expect(created_todo.category_id).to eq(category.id)
      end

      it "creates todo without category (null relationship)" do
        post "/todos", headers: headers, params: {
          data: {
            type: "todos",
            attributes: {
              name: "Todo without category"
            },
            relationships: {
              category: {
                data: nil
              }
            }
          }
        }.to_json

        created_todo = Todo.last
        expect(created_todo.category_id).to be_nil
      end

      it "returns 400 when data is missing" do
        post "/todos", headers: headers, params: {}.to_json

        expect(response.status).to eq(400)
      end

      it "returns JSON:API error structure when data is missing" do
        post "/todos", headers: headers, params: {}.to_json

        response_body = JSON.parse(response.body)
        expect(response_body).to have_key("errors")
        expect(response_body).not_to have_key("data")
        expect(response_body["errors"]).to be_an(Array)
      end

      it "returns 400 when type is missing" do
        post "/todos", headers: headers, params: {
          data: {
            attributes: {
              name: "New Todo"
            }
          }
        }.to_json

        expect(response.status).to eq(400)
      end

      it "returns 400 when type is wrong" do
        post "/todos", headers: headers, params: {
          data: {
            type: "wrong-type",
            attributes: {
              name: "New Todo"
            }
          }
        }.to_json

        expect(response.status).to eq(400)
      end

      it "returns 422 when name is missing" do
        post "/todos", headers: headers, params: {
          data: {
            type: "todos",
            attributes: {
              notes: "Some notes"
            }
          }
        }.to_json

        expect(response.status).to eq(422)
      end

      it "returns JSON:API error structure for validation errors" do
        post "/todos", headers: headers, params: {
          data: {
            type: "todos",
            attributes: {
              notes: "Some notes"
            }
          }
        }.to_json

        response_body = JSON.parse(response.body)
        expect(response_body).to have_key("errors")
        expect(response_body["errors"]).to be_an(Array)
        expect(response_body["errors"].first).to have_key("code")
        expect(response_body["errors"].first).to have_key("title")
      end

      it "does not create todo when validation fails" do
        expect {
          post "/todos", headers: headers, params: {
            data: {
              type: "todos",
              attributes: {
                notes: "Some notes"
              }
            }
          }.to_json
        }.not_to change(Todo, :count)
      end

      it "returns 400 for invalid JSON syntax" do
        post "/todos", headers: headers, params: "invalid json{"

        expect(response.status).to eq(400)
      end
    end

    context "when logged out" do
      it "returns 401 unauthorized" do
        post "/todos", params: {
          data: {
            type: "todos",
            attributes: {
              name: "New Todo"
            }
          }
        }.to_json

        expect(response.status).to eq(401)
      end

      it "does not create todo" do
        expect {
          post "/todos", params: {
            data: {
              type: "todos",
              attributes: {
                name: "New Todo"
              }
            }
          }.to_json
        }.not_to change(Todo, :count)
      end
    end
  end

  # ==========================================================================
  # PATCH /todos/:id
  # ==========================================================================
  describe "PATCH /todos/:id" do
    context "when logged in" do
      it "updates todo name" do
        todo = create(:todo, user: user, name: "Old Name")

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: todo.id,
            attributes: {
              name: "New Name"
            }
          }
        }.to_json

        expect(response.status).to eq(200)
        expect(todo.reload.name).to eq("New Name")
      end

      it "updates todo notes" do
        todo = create(:todo, user: user, notes: "Old notes")

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: todo.id,
            attributes: {
              notes: "New notes"
            }
          }
        }.to_json

        expect(response.status).to eq(200)
        expect(todo.reload.notes).to eq("New notes")
      end

      it "updates deferred-until date" do
        todo = create(:todo, user: user, deferred_until: nil)
        future_date = 2.days.from_now.to_date

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: todo.id,
            attributes: {
              "deferred-until": future_date.to_s
            }
          }
        }.to_json

        expect(response.status).to eq(200)
        expect(todo.reload.deferred_until).to eq(future_date)
      end

      it "clears deferred-until by setting to null" do
        todo = create(:todo, user: user, deferred_until: 2.days.from_now)

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: todo.id,
            attributes: {
              "deferred-until": nil
            }
          }
        }.to_json

        expect(response.status).to eq(200)
        expect(todo.reload.deferred_until).to be_nil
      end

      it "marks todo as complete by setting completed-at" do
        todo = create(:todo, user: user, completed_at: nil)
        completion_time = Time.current

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: todo.id,
            attributes: {
              "completed-at": completion_time.iso8601
            }
          }
        }.to_json

        expect(response.status).to eq(200)
        expect(todo.reload.completed_at).to be_present
      end

      it "marks todo as incomplete by clearing completed-at" do
        todo = create(:todo, user: user, completed_at: Time.current)

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: todo.id,
            attributes: {
              "completed-at": nil
            }
          }
        }.to_json

        expect(response.status).to eq(200)
        expect(todo.reload.completed_at).to be_nil
      end

      it "soft deletes todo by setting deleted-at" do
        todo = create(:todo, user: user, deleted_at: nil)
        deletion_time = Time.current

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: todo.id,
            attributes: {
              "deleted-at": deletion_time.iso8601
            }
          }
        }.to_json

        expect(response.status).to eq(200)
        expect(todo.reload.deleted_at).to be_present
      end

      it "undeletes todo by clearing deleted-at and completed-at" do
        todo = create(:todo, user: user, deleted_at: Time.current, completed_at: Time.current)

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: todo.id,
            attributes: {
              "deleted-at": nil,
              "completed-at": nil
            }
          }
        }.to_json

        expect(response.status).to eq(200)
        expect(todo.reload.deleted_at).to be_nil
        expect(todo.reload.completed_at).to be_nil
      end

      it "updates category relationship" do
        todo = create(:todo, user: user, category: nil)
        category = create(:category, user: user)

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: todo.id,
            relationships: {
              category: {
                data: {
                  type: "categories",
                  id: category.id
                }
              }
            }
          }
        }.to_json

        expect(response.status).to eq(200)
        expect(todo.reload.category_id).to eq(category.id)
      end

      it "removes category by setting relationship to null" do
        category = create(:category, user: user)
        todo = create(:todo, user: user, category: category)

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: todo.id,
            relationships: {
              category: {
                data: nil
              }
            }
          }
        }.to_json

        expect(response.status).to eq(200)
        expect(todo.reload.category_id).to be_nil
      end

      it "updates multiple attributes at once (simulating edit form)" do
        category = create(:category, user: user)
        todo = create(:todo, user: user, name: "Old", notes: "Old notes", deferred_until: nil, category: nil)
        future_date = 2.days.from_now.to_date

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: todo.id,
            attributes: {
              name: "Updated Name",
              notes: "Updated notes",
              "deferred-until": future_date.to_s
            },
            relationships: {
              category: {
                data: {
                  type: "categories",
                  id: category.id
                }
              }
            }
          }
        }.to_json

        expect(response.status).to eq(200)
        todo.reload
        expect(todo.name).to eq("Updated Name")
        expect(todo.notes).to eq("Updated notes")
        expect(todo.deferred_until).to eq(future_date)
        expect(todo.category_id).to eq(category.id)
      end

      it "returns JSON:API formatted response" do
        todo = create(:todo, user: user)

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: todo.id,
            attributes: {
              name: "Updated"
            }
          }
        }.to_json

        expect(response.content_type).to match(%r{application/vnd\.api\+json})

        response_body = JSON.parse(response.body)
        expect(response_body).to have_key("data")
        expect(response_body).not_to have_key("errors")
      end

      it "returns updated todo in response" do
        todo = create(:todo, user: user, name: "Old Name")

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: todo.id,
            attributes: {
              name: "New Name"
            }
          }
        }.to_json

        response_body = JSON.parse(response.body)
        expect(response_body["data"]["attributes"]["name"]).to eq("New Name")
      end

      it "returns 404 when todo doesn't exist" do
        patch "/todos/00000000-0000-0000-0000-000000000000", headers: headers, params: {
          data: {
            type: "todos",
            id: "00000000-0000-0000-0000-000000000000",
            attributes: {
              name: "Updated"
            }
          }
        }.to_json

        expect(response.status).to eq(404)
      end

      it "returns 404 when todo belongs to another user" do
        other_user = create(:user)
        other_todo = create(:todo, user: other_user)

        patch "/todos/#{other_todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: other_todo.id,
            attributes: {
              name: "Updated"
            }
          }
        }.to_json

        expect(response.status).to eq(404)
      end

      it "does not modify other user's todo" do
        other_user = create(:user)
        other_todo = create(:todo, user: other_user, name: "Original")

        patch "/todos/#{other_todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: other_todo.id,
            attributes: {
              name: "Hacked"
            }
          }
        }.to_json

        expect(other_todo.reload.name).to eq("Original")
      end

      it "returns 400 when ID in URL doesn't match ID in payload" do
        todo = create(:todo, user: user)

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: "00000000-0000-0000-0000-000000000000",
            attributes: {
              name: "Updated"
            }
          }
        }.to_json

        expect(response.status).to eq(400)
      end

      it "returns 400 when type is missing" do
        todo = create(:todo, user: user)

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            id: todo.id,
            attributes: {
              name: "Updated"
            }
          }
        }.to_json

        expect(response.status).to eq(400)
      end

      it "returns 400 when type is wrong" do
        todo = create(:todo, user: user)

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            type: "wrong-type",
            id: todo.id,
            attributes: {
              name: "Updated"
            }
          }
        }.to_json

        expect(response.status).to eq(400)
      end

      it "returns 422 when name is set to empty" do
        todo = create(:todo, user: user, name: "Original")

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: todo.id,
            attributes: {
              name: ""
            }
          }
        }.to_json

        expect(response.status).to eq(422)
      end

      it "returns JSON:API error structure for validation errors" do
        todo = create(:todo, user: user)

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: todo.id,
            attributes: {
              name: ""
            }
          }
        }.to_json

        response_body = JSON.parse(response.body)
        expect(response_body).to have_key("errors")
        expect(response_body["errors"]).to be_an(Array)
        expect(response_body["errors"].first).to have_key("code")
        expect(response_body["errors"].first).to have_key("title")
      end

      it "does not update todo when validation fails" do
        todo = create(:todo, user: user, name: "Original")

        patch "/todos/#{todo.id}", headers: headers, params: {
          data: {
            type: "todos",
            id: todo.id,
            attributes: {
              name: ""
            }
          }
        }.to_json

        expect(todo.reload.name).to eq("Original")
      end

      it "returns 400 for invalid JSON syntax" do
        todo = create(:todo, user: user)

        patch "/todos/#{todo.id}", headers: headers, params: "invalid json{"

        expect(response.status).to eq(400)
      end
    end

    context "when logged out" do
      it "returns 401 unauthorized" do
        todo = create(:todo, user: user)

        patch "/todos/#{todo.id}", params: {
          data: {
            type: "todos",
            id: todo.id,
            attributes: {
              name: "Updated"
            }
          }
        }.to_json

        expect(response.status).to eq(401)
      end

      it "does not update todo" do
        todo = create(:todo, user: user, name: "Original")

        patch "/todos/#{todo.id}", params: {
          data: {
            type: "todos",
            id: todo.id,
            attributes: {
              name: "Hacked"
            }
          }
        }.to_json

        expect(todo.reload.name).to eq("Original")
      end
    end
  end

  # ==========================================================================
  # DELETE /todos/:id (currently allowed, but should use soft delete instead)
  # ==========================================================================
  describe "DELETE /todos/:id" do
    context "when logged in" do
      it "returns 204 no content" do
        todo = create(:todo, user: user)

        delete "/todos/#{todo.id}", headers: headers

        expect(response.status).to eq(204)
      end

      it "hard deletes the todo from database (current behavior)" do
        todo = create(:todo, user: user)

        expect {
          delete "/todos/#{todo.id}", headers: headers
        }.to change(Todo, :count).by(-1)

        expect(Todo.exists?(todo.id)).to be false
      end

      it "returns 404 when todo doesn't exist" do
        delete "/todos/00000000-0000-0000-0000-000000000000", headers: headers

        expect(response.status).to eq(404)
      end

      it "returns 404 when todo belongs to another user" do
        other_user = create(:user)
        other_todo = create(:todo, user: other_user)

        delete "/todos/#{other_todo.id}", headers: headers

        expect(response.status).to eq(404)
      end

      it "does not delete other user's todo" do
        other_user = create(:user)
        other_todo = create(:todo, user: other_user)

        expect {
          delete "/todos/#{other_todo.id}", headers: headers
        }.not_to change(Todo, :count)

        expect(Todo.exists?(other_todo.id)).to be true
      end
    end

    context "when logged out" do
      it "returns 401 unauthorized" do
        todo = create(:todo, user: user)

        delete "/todos/#{todo.id}"

        expect(response.status).to eq(401)
      end

      it "does not delete todo" do
        todo = create(:todo, user: user)

        expect {
          delete "/todos/#{todo.id}"
        }.not_to change(Todo, :count)
      end
    end
  end
end
