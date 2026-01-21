# frozen_string_literal: true

class CategoriesController < JsonapiController
  before_action :doorkeeper_authorize!
  before_action :set_category, only: [:show, :update, :destroy]

  def index
    categories = current_user.categories
    render json: {data: categories.map { |c| serialize_category(c) }}, content_type: jsonapi_content_type
  end

  def show
    render json: {data: serialize_category(@category)}, content_type: jsonapi_content_type
  end

  def create
    result = validate_jsonapi_request("categories")
    return if result == :error

    attributes = result[:attributes]

    category = current_user.categories.new(
      name: attributes["name"],
      sort_order: attributes["sort-order"]
    )

    if category.save
      render json: {data: serialize_category(category)}, status: :created, content_type: jsonapi_content_type
    else
      render_validation_errors(category)
    end
  rescue ActiveRecord::NotNullViolation
    # Database constraint violation (e.g., name is NULL)
    render json: {errors: [{code: "500", title: "Database constraint violation"}]}, status: :internal_server_error, content_type: jsonapi_content_type
  end

  def update
    result = validate_jsonapi_request("categories", require_id: true, expected_id: params[:id])
    return if result == :error

    attributes = result[:attributes]

    update_params = {}
    update_params[:name] = attributes["name"] if attributes.key?("name")
    update_params[:sort_order] = attributes["sort-order"] if attributes.key?("sort-order")

    if @category.update(update_params)
      render json: {data: serialize_category(@category)}, content_type: jsonapi_content_type
    else
      render_validation_errors(@category)
    end
  end

  def destroy
    @category.destroy
    head :no_content
  end

  private

  def set_category
    @category = current_user.categories.find_by(id: params[:id])
    render_not_found unless @category
  end

  def serialize_category(category)
    {
      type: "categories",
      id: category.id.to_s,
      attributes: {
        "name" => category.name,
        "sort-order" => category.sort_order
      }
    }
  end
end
