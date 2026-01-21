# frozen_string_literal: true

require "rails_helper"

RSpec.describe "categories", type: :request do
  include_context "with a logged in user"

  let(:json_api_headers) do
    {
      "Content-Type" => "application/vnd.api+json"
    }
  end

  describe "GET /categories" do
    context "when logged in" do
      it "returns successful response" do
        get "/categories", headers: headers

        expect(response.status).to eq(200)
      end

      it "returns JSON:API formatted response" do
        get "/categories", headers: headers

        expect(response.content_type).to match(%r{application/vnd\.api\+json})

        response_body = JSON.parse(response.body)
        expect(response_body).to have_key("data")
        expect(response_body).not_to have_key("errors")
      end

      it "returns array of categories" do
        get "/categories", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"]).to be_an(Array)
      end

      it "returns all user's categories" do
        category1 = create(:category, user: user, name: "Work")
        category2 = create(:category, user: user, name: "Personal")

        get "/categories", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(2)

        ids = response_body["data"].map { |c| c["id"] }
        expect(ids).to contain_exactly(category1.id, category2.id)
      end

      it "returns empty array when user has no categories" do
        get "/categories", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"]).to eq([])
      end

      it "returns categories with correct structure" do
        create(:category, user: user, name: "Work", sort_order: 1)

        get "/categories", headers: headers

        response_body = JSON.parse(response.body)
        category_data = response_body["data"].first

        expect(category_data["type"]).to eq("categories")
        expect(category_data["id"]).to be_present
        expect(category_data).to have_key("attributes")
      end

      it "returns all category attributes" do
        create(:category, user: user, name: "Work", sort_order: 5)

        get "/categories", headers: headers

        response_body = JSON.parse(response.body)
        attributes = response_body["data"].first["attributes"]

        expect(attributes["name"]).to eq("Work")
        expect(attributes["sort-order"]).to eq(5)
      end

      it "transforms snake_case to kebab-case in attributes" do
        create(:category, user: user, sort_order: 3)

        get "/categories", headers: headers

        response_body = JSON.parse(response.body)
        attributes = response_body["data"].first["attributes"]

        expect(attributes).to have_key("sort-order")
        expect(attributes).not_to have_key("sort_order")
      end

      it "does not return other users' categories" do
        other_user = create(:user)
        create(:category, user: other_user, name: "Other User Category")
        create(:category, user: user, name: "My Category")

        get "/categories", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"].length).to eq(1)
        expect(response_body["data"].first["attributes"]["name"]).to eq("My Category")
      end
    end

    context "when logged out" do
      it "returns 401 unauthorized" do
        get "/categories", headers: json_api_headers

        expect(response.status).to eq(401)
      end

      it "returns empty response body for 401" do
        get "/categories", headers: json_api_headers

        expect(response.body).to be_empty
      end
    end
  end

  describe "GET /categories/:id" do
    let(:category) { create(:category, user: user, name: "Test Category", sort_order: 2) }

    context "when logged in" do
      it "returns successful response" do
        get "/categories/#{category.id}", headers: headers

        expect(response.status).to eq(200)
      end

      it "returns JSON:API formatted response" do
        get "/categories/#{category.id}", headers: headers

        expect(response.content_type).to match(%r{application/vnd\.api\+json})

        response_body = JSON.parse(response.body)
        expect(response_body).to have_key("data")
        expect(response_body).not_to have_key("errors")
      end

      it "returns single category (Hash, not Array)" do
        get "/categories/#{category.id}", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"]).to be_a(Hash)
        expect(response_body["data"]).not_to be_an(Array)
      end

      it "returns the correct category" do
        get "/categories/#{category.id}", headers: headers

        response_body = JSON.parse(response.body)
        expect(response_body["data"]["id"]).to eq(category.id)
      end

      it "returns category with correct structure" do
        get "/categories/#{category.id}", headers: headers

        response_body = JSON.parse(response.body)
        data = response_body["data"]

        expect(data["type"]).to eq("categories")
        expect(data["id"]).to be_present
        expect(data).to have_key("attributes")
      end

      it "returns all category attributes" do
        get "/categories/#{category.id}", headers: headers

        response_body = JSON.parse(response.body)
        attributes = response_body["data"]["attributes"]

        expect(attributes["name"]).to eq("Test Category")
        expect(attributes["sort-order"]).to eq(2)
      end

      it "returns 404 for non-existent category" do
        get "/categories/00000000-0000-0000-0000-000000000000", headers: headers

        expect(response.status).to eq(404)
      end

      it "returns 404 for other user's category" do
        other_user = create(:user)
        other_category = create(:category, user: other_user)

        get "/categories/#{other_category.id}", headers: headers

        expect(response.status).to eq(404)
      end
    end

    context "when logged out" do
      it "returns 401 unauthorized" do
        get "/categories/#{category.id}", headers: json_api_headers

        expect(response.status).to eq(401)
      end

      it "returns empty response body for 401" do
        get "/categories/#{category.id}", headers: json_api_headers

        expect(response.body).to be_empty
      end
    end
  end

  describe "POST /categories" do
    context "when logged in" do
      let(:valid_attributes) do
        {
          data: {
            type: "categories",
            attributes: {
              name: "New Category"
            }
          }
        }
      end

      it "creates a new category successfully" do
        expect {
          post "/categories", headers: headers, params: valid_attributes.to_json
        }.to change(Category, :count).by(1)

        expect(response.status).to eq(201)
      end

      it "returns JSON:API formatted response" do
        post "/categories", headers: headers, params: valid_attributes.to_json

        expect(response.content_type).to match(%r{application/vnd\.api\+json})

        response_body = JSON.parse(response.body)
        expect(response_body).to have_key("data")
        expect(response_body).not_to have_key("errors")
      end

      it "returns the created category with correct structure" do
        post "/categories", headers: headers, params: valid_attributes.to_json

        response_body = JSON.parse(response.body)
        data = response_body["data"]

        expect(data["type"]).to eq("categories")
        expect(data["id"]).to be_present
        expect(data).to have_key("attributes")
      end

      it "returns the category's name attribute" do
        post "/categories", headers: headers, params: valid_attributes.to_json

        response_body = JSON.parse(response.body)
        attributes = response_body["data"]["attributes"]

        expect(attributes["name"]).to eq("New Category")
      end

      it "returns the category's sort-order attribute" do
        post "/categories", headers: headers, params: valid_attributes.to_json

        response_body = JSON.parse(response.body)
        attributes = response_body["data"]["attributes"]

        expect(attributes["sort-order"]).to be_present
        expect(attributes["sort-order"]).to be_a(Integer)
      end

      it "associates category with authenticated user" do
        post "/categories", headers: headers, params: valid_attributes.to_json

        response_body = JSON.parse(response.body)
        category_id = response_body["data"]["id"]
        category = Category.find(category_id)
        expect(category.user_id).to eq(user.id)
      end

      it "sets the sort order to 1 for first category" do
        body = {
          data: {
            type: "categories",
            attributes: {name: "First Category"}
          }
        }
        post "/categories", headers: headers, params: body.to_json

        expect(response.status).to eq(201)

        response_body = JSON.parse(response.body)
        expect(response_body["data"]["attributes"]["sort-order"]).to eq(1)
      end

      it "sets the sort order to one more than the max" do
        create(:category, user: user, sort_order: 1)
        create(:category, user: user, sort_order: 3)

        body = {
          data: {
            type: "categories",
            attributes: {name: "New Category"}
          }
        }
        post "/categories", headers: headers, params: body.to_json

        expect(response.status).to eq(201)

        response_body = JSON.parse(response.body)
        expect(response_body["data"]["attributes"]["sort-order"]).to eq(4)
      end

      it "allows explicitly setting sort-order on create" do
        body = {
          data: {
            type: "categories",
            attributes: {
              name: "Explicit Sort",
              "sort-order": 10
            }
          }
        }
        post "/categories", headers: headers, params: body.to_json

        expect(response.status).to eq(201)

        response_body = JSON.parse(response.body)
        expect(response_body["data"]["attributes"]["sort-order"]).to eq(10)
      end
    end

    context "when logged out" do
      it "returns 401 unauthorized" do
        body = {
          data: {
            type: "categories",
            attributes: {
              name: "Unauthorized Category"
            }
          }
        }

        post "/categories", headers: json_api_headers, params: body.to_json

        expect(response.status).to eq(401)
      end

      it "returns empty response body for 401" do
        body = {
          data: {
            type: "categories",
            attributes: {
              name: "Unauthorized Category"
            }
          }
        }

        post "/categories", headers: json_api_headers, params: body.to_json

        expect(response.body).to be_empty
      end

      it "does not create a category when unauthorized" do
        body = {
          data: {
            type: "categories",
            attributes: {
              name: "Unauthorized Category"
            }
          }
        }

        expect {
          post "/categories", headers: json_api_headers, params: body.to_json
        }.not_to change(Category, :count)
      end
    end

    context "with validation errors" do
      # Note: Category model has database constraint (NOT NULL) on name
      it "returns 500 when name is missing (database constraint)" do
        body = {
          data: {
            type: "categories",
            attributes: {}
          }
        }

        post "/categories", headers: headers, params: body.to_json

        # Current implementation returns 500 for database constraint violations
        expect(response.status).to eq(500)
      end

      it "allows creating category with blank name string" do
        body = {
          data: {
            type: "categories",
            attributes: {
              name: ""
            }
          }
        }

        expect {
          post "/categories", headers: headers, params: body.to_json
        }.to change(Category, :count).by(1)

        expect(response.status).to eq(201)
      end
    end

    context "with invalid JSON:API format" do
      it "returns 400 when data key is missing" do
        body = {
          type: "categories",
          attributes: {
            name: "Invalid Format"
          }
        }

        post "/categories", headers: headers, params: body.to_json

        expect(response.status).to eq(400)
      end

      it "returns JSON:API error structure when data key is missing" do
        body = {
          type: "categories",
          attributes: {
            name: "Invalid Format"
          }
        }

        post "/categories", headers: headers, params: body.to_json

        response_body = JSON.parse(response.body)
        expect(response_body).to have_key("errors")
        expect(response_body["errors"]).to be_an(Array)
      end

      it "returns 400 when type key is missing" do
        body = {
          data: {
            attributes: {
              name: "No Type"
            }
          }
        }

        post "/categories", headers: headers, params: body.to_json

        expect(response.status).to eq(400)
      end

      it "returns 400 when type is incorrect" do
        body = {
          data: {
            type: "widgets",
            attributes: {
              name: "Wrong Type"
            }
          }
        }

        post "/categories", headers: headers, params: body.to_json

        expect(response.status).to eq(400)
      end

      it "returns 400 when JSON is malformed" do
        post "/categories", headers: headers, params: "{ invalid json"

        expect(response.status).to eq(400)
      end
    end

    context "attribute naming" do
      it "accepts attributes in kebab-case format" do
        body = {
          data: {
            type: "categories",
            attributes: {
              name: "Kebab Case",
              "sort-order": 5
            }
          }
        }

        post "/categories", headers: headers, params: body.to_json

        expect(response.status).to eq(201)

        category = Category.last
        expect(category.sort_order).to eq(5)
      end
    end
  end

  describe "PATCH /categories/:id" do
    let(:category) { create(:category, user: user, name: "Original Name", sort_order: 5) }

    context "when logged in" do
      it "updates the category successfully" do
        body = {
          data: {
            type: "categories",
            id: category.id,
            attributes: {
              name: "Updated Name"
            }
          }
        }

        patch "/categories/#{category.id}", headers: headers, params: body.to_json

        expect(response.status).to eq(200)

        category.reload
        expect(category.name).to eq("Updated Name")
      end

      it "returns JSON:API formatted response" do
        body = {
          data: {
            type: "categories",
            id: category.id,
            attributes: {
              name: "Updated Name"
            }
          }
        }

        patch "/categories/#{category.id}", headers: headers, params: body.to_json

        expect(response.content_type).to match(%r{application/vnd\.api\+json})

        response_body = JSON.parse(response.body)
        expect(response_body).to have_key("data")
        expect(response_body).not_to have_key("errors")
      end

      it "returns the updated category" do
        body = {
          data: {
            type: "categories",
            id: category.id,
            attributes: {
              name: "Updated Name"
            }
          }
        }

        patch "/categories/#{category.id}", headers: headers, params: body.to_json

        response_body = JSON.parse(response.body)
        expect(response_body["data"]["attributes"]["name"]).to eq("Updated Name")
      end

      it "updates the name attribute" do
        body = {
          data: {
            type: "categories",
            id: category.id,
            attributes: {
              name: "New Name"
            }
          }
        }

        patch "/categories/#{category.id}", headers: headers, params: body.to_json

        category.reload
        expect(category.name).to eq("New Name")
      end

      it "updates the sort-order attribute" do
        body = {
          data: {
            type: "categories",
            id: category.id,
            attributes: {
              "sort-order": 10
            }
          }
        }

        patch "/categories/#{category.id}", headers: headers, params: body.to_json

        expect(response.status).to eq(200)

        category.reload
        expect(category.sort_order).to eq(10)
      end

      it "updates multiple attributes" do
        body = {
          data: {
            type: "categories",
            id: category.id,
            attributes: {
              name: "Multi Update",
              "sort-order": 15
            }
          }
        }

        patch "/categories/#{category.id}", headers: headers, params: body.to_json

        category.reload
        expect(category.name).to eq("Multi Update")
        expect(category.sort_order).to eq(15)
      end

      it "returns 404 for non-existent category" do
        body = {
          data: {
            type: "categories",
            id: "00000000-0000-0000-0000-000000000000",
            attributes: {
              name: "Not Found"
            }
          }
        }

        patch "/categories/00000000-0000-0000-0000-000000000000", headers: headers, params: body.to_json

        expect(response.status).to eq(404)
      end

      it "returns 404 for other user's category" do
        other_user = create(:user)
        other_category = create(:category, user: other_user)

        body = {
          data: {
            type: "categories",
            id: other_category.id,
            attributes: {
              name: "Hacked"
            }
          }
        }

        patch "/categories/#{other_category.id}", headers: headers, params: body.to_json

        expect(response.status).to eq(404)

        other_category.reload
        expect(other_category.name).not_to eq("Hacked")
      end

      it "returns 400 when ID in URL doesn't match ID in payload" do
        body = {
          data: {
            type: "categories",
            id: "00000000-0000-0000-0000-000000000000",
            attributes: {
              name: "Mismatched"
            }
          }
        }

        patch "/categories/#{category.id}", headers: headers, params: body.to_json

        expect(response.status).to eq(400)
      end
    end

    context "when logged out" do
      it "returns 401 unauthorized" do
        body = {
          data: {
            type: "categories",
            id: category.id,
            attributes: {
              name: "Unauthorized Update"
            }
          }
        }

        patch "/categories/#{category.id}", headers: json_api_headers, params: body.to_json

        expect(response.status).to eq(401)
      end

      it "returns empty response body for 401" do
        body = {
          data: {
            type: "categories",
            id: category.id,
            attributes: {
              name: "Unauthorized Update"
            }
          }
        }

        patch "/categories/#{category.id}", headers: json_api_headers, params: body.to_json

        expect(response.body).to be_empty
      end

      it "does not update the category when unauthorized" do
        body = {
          data: {
            type: "categories",
            id: category.id,
            attributes: {
              name: "Unauthorized Update"
            }
          }
        }

        patch "/categories/#{category.id}", headers: json_api_headers, params: body.to_json

        category.reload
        expect(category.name).to eq("Original Name")
      end
    end

    context "with validation errors" do
      # Note: Category model currently has no validations on name
      # These tests document the current behavior (no validation)
      it "allows updating name to blank" do
        body = {
          data: {
            type: "categories",
            id: category.id,
            attributes: {
              name: ""
            }
          }
        }

        patch "/categories/#{category.id}", headers: headers, params: body.to_json

        expect(response.status).to eq(200)

        category.reload
        expect(category.name).to eq("")
      end
    end

    context "with invalid JSON:API format" do
      it "returns 400 when data key is missing" do
        body = {
          type: "categories",
          id: category.id,
          attributes: {
            name: "Invalid"
          }
        }

        patch "/categories/#{category.id}", headers: headers, params: body.to_json

        expect(response.status).to eq(400)
      end

      it "returns 400 when type is incorrect" do
        body = {
          data: {
            type: "widgets",
            id: category.id,
            attributes: {
              name: "Wrong Type"
            }
          }
        }

        patch "/categories/#{category.id}", headers: headers, params: body.to_json

        expect(response.status).to eq(400)
      end
    end
  end

  describe "DELETE /categories/:id" do
    let!(:category) { create(:category, user: user, name: "To Delete") }

    context "when logged in" do
      it "deletes the category successfully" do
        expect {
          delete "/categories/#{category.id}", headers: headers
        }.to change(Category, :count).by(-1)

        expect(response.status).to eq(204)
      end

      it "returns 204 No Content" do
        delete "/categories/#{category.id}", headers: headers

        expect(response.status).to eq(204)
      end

      it "returns empty response body" do
        delete "/categories/#{category.id}", headers: headers

        expect(response.body).to be_empty
      end

      it "hard deletes the category (not soft delete)" do
        delete "/categories/#{category.id}", headers: headers

        expect(Category.find_by(id: category.id)).to be_nil
      end

      it "returns 404 for non-existent category" do
        delete "/categories/00000000-0000-0000-0000-000000000000", headers: headers

        expect(response.status).to eq(404)
      end

      it "returns 404 for other user's category" do
        other_user = create(:user)
        other_category = create(:category, user: other_user)

        delete "/categories/#{other_category.id}", headers: headers

        expect(response.status).to eq(404)
        expect(Category.find_by(id: other_category.id)).to be_present
      end

      it "does not delete other user's category" do
        other_user = create(:user)
        other_category = create(:category, user: other_user)

        expect {
          delete "/categories/#{other_category.id}", headers: headers
        }.not_to change(Category, :count)
      end
    end

    context "when logged out" do
      it "returns 401 unauthorized" do
        delete "/categories/#{category.id}", headers: json_api_headers

        expect(response.status).to eq(401)
      end

      it "returns empty response body for 401" do
        delete "/categories/#{category.id}", headers: json_api_headers

        expect(response.body).to be_empty
      end

      it "does not delete the category when unauthorized" do
        expect {
          delete "/categories/#{category.id}", headers: json_api_headers
        }.not_to change(Category, :count)

        expect(Category.find_by(id: category.id)).to be_present
      end
    end
  end
end
