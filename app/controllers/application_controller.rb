class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def render_not_found(exception)
    render json: { error: exception.message }, status: :not_found
  end

  def render_unprocessable(resource)
    render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
  end

  def render_forbidden(message = "You are not allowed to perform this action.")
    render json: { error: message }, status: :forbidden
  end
end
