# frozen_string_literal: true

class TodosController < JsonapiController
  before_action :doorkeeper_authorize!
  before_action :set_todo, only: [:show, :update, :destroy]

  def index
    todos = current_user.todos

    # Apply status filter
    if params[:filter] && params[:filter][:status]
      todos = todos.status(params[:filter][:status])
    end

    # Apply search filter
    if params[:filter] && params[:filter][:search]
      todos = todos.where("name ILIKE ?", "%#{params[:filter][:search]}%")
    end

    # Apply sorting
    if params[:sort]
      sort_field = params[:sort].start_with?("-") ? params[:sort][1..] : params[:sort]
      sort_direction = params[:sort].start_with?("-") ? :desc : :asc

      case sort_field
      when "name"
        todos = todos.order(name: sort_direction)
      when "completedAt"
        todos = todos.order(completed_at: sort_direction)
      when "deletedAt"
        todos = todos.order(deleted_at: sort_direction)
      end
    end

    # Apply pagination for completed and deleted statuses
    page_count = nil
    if params[:filter] && params[:filter][:status].in?(["completed", "deleted"])
      page_number = (params[:page] && params[:page][:number]) || 1
      per_page = 10
      total_count = todos.count
      page_count = (total_count.to_f / per_page).ceil

      todos = todos.offset((page_number.to_i - 1) * per_page).limit(per_page)
    end

    # Check if we need to include categories
    include_category = params[:include] == "category"

    # Preload categories if needed
    todos = todos.includes(:category) if include_category

    # Serialize todos
    data = todos.map { |t| serialize_todo(t, include_relationships: include_category) }

    # Build included array if needed
    response_json = {data: data}

    if include_category
      # Get unique categories from todos
      categories = todos.map(&:category).compact.uniq
      if categories.any?
        response_json[:included] = categories.map { |c| serialize_category(c) }
      end
    end

    # Add pagination meta if needed
    if page_count
      response_json[:meta] = {"page-count" => page_count}
    end

    render json: response_json, content_type: jsonapi_content_type
  end

  def show
    include_category = params[:include] == "category"
    data = serialize_todo(@todo, include_relationships: include_category)

    response_json = {data: data}

    if include_category && @todo.category
      response_json[:included] = [serialize_category(@todo.category)]
    end

    render json: response_json, content_type: jsonapi_content_type
  end

  def create
    result = validate_jsonapi_request("todos")
    return if result == :error

    attributes = result[:attributes]
    relationships = result[:relationships]

    todo = current_user.todos.new(
      name: attributes["name"],
      notes: attributes["notes"],
      deferred_until: attributes["deferred-until"],
      completed_at: attributes["completed-at"],
      deleted_at: attributes["deleted-at"]
    )

    # Handle category relationship
    if relationships && relationships["category"]
      category_data = relationships["category"]["data"]
      if category_data.nil?
        todo.category = nil
      elsif category_data.is_a?(Hash) && category_data["id"]
        todo.category_id = category_data["id"]
      end
    end

    if todo.save
      render json: {data: serialize_todo(todo, include_relationships: true)}, status: :created, content_type: jsonapi_content_type
    else
      render_validation_errors(todo)
    end
  end

  def update
    result = validate_jsonapi_request("todos", require_id: true, expected_id: params[:id])
    return if result == :error

    attributes = result[:attributes]
    relationships = result[:relationships]

    update_params = {}
    update_params[:name] = attributes["name"] if attributes.key?("name")
    update_params[:notes] = attributes["notes"] if attributes.key?("notes")
    update_params[:deferred_until] = attributes["deferred-until"] if attributes.key?("deferred-until")
    update_params[:completed_at] = attributes["completed-at"] if attributes.key?("completed-at")
    update_params[:deleted_at] = attributes["deleted-at"] if attributes.key?("deleted-at")

    # Handle category relationship
    if relationships && relationships["category"]
      category_data = relationships["category"]["data"]
      if category_data.nil?
        update_params[:category_id] = nil
      elsif category_data.is_a?(Hash) && category_data["id"]
        update_params[:category_id] = category_data["id"]
      end
    end

    if @todo.update(update_params)
      render json: {data: serialize_todo(@todo, include_relationships: true)}, content_type: jsonapi_content_type
    else
      render_validation_errors(@todo)
    end
  end

  def destroy
    @todo.destroy
    head :no_content
  end

  private

  def set_todo
    @todo = current_user.todos.find_by(id: params[:id])
    render_not_found unless @todo
  end

  def serialize_todo(todo, include_relationships: false)
    serialized = {
      type: "todos",
      id: todo.id.to_s,
      attributes: {
        "name" => todo.name,
        "notes" => todo.notes,
        "completed-at" => todo.completed_at&.iso8601,
        "deleted-at" => todo.deleted_at&.iso8601,
        "deferred-until" => todo.deferred_until&.to_time&.iso8601,
        "created-at" => todo.created_at&.iso8601,
        "updated-at" => todo.updated_at&.iso8601,
        "deferred-at" => todo.deferred_at&.iso8601
      }
    }

    if include_relationships
      serialized[:relationships] = {
        "category" => {
          "data" => todo.category ? {type: "categories", id: todo.category_id.to_s} : nil
        }
      }
    end

    serialized
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
