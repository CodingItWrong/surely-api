# frozen_string_literal: true

class UsersController < JsonapiController
  # Public endpoint - no authentication required

  def create
    result = validate_jsonapi_request("users")
    return if result == :error

    attributes = result[:attributes]

    user = User.new(
      email: attributes["email"],
      password: attributes["password"]
    )

    if user.save
      render json: {data: serialize_user(user)}, status: :created, content_type: jsonapi_content_type
    else
      render_validation_errors(user)
    end
  end

  private

  def serialize_user(user)
    {
      type: "users",
      id: user.id.to_s,
      attributes: {
        "email" => user.email,
        "password" => nil
      }
    }
  end
end
