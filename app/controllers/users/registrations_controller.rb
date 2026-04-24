class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  private

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
