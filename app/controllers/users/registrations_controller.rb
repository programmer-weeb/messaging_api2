class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private

  # This stops Devise from storing session after user create.
  # Authenticate through Warden so devise-jwt can dispatch a token,
  # but do not persist anything in a session for this API-only app.
  def sign_up(resource_name, resource)
    sign_in(resource_name, resource, store: false)
  end

  def respond_with(resource, _opts = {})
    if resource.persisted?
      render json: {
        message: "Signed up successfully.",
        user: resource
      }, status: :created
    else
      render json: {
        message: "Signup failed.",
        errors: resource.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
end
