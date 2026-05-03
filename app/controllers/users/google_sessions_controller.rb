class Users::GoogleSessionsController < DeviseController
  respond_to :json

  def create
    payload = GoogleIdTokenVerifier.verify!(id_token: google_params.fetch(:id_token))
    user = Users::GoogleAccountProvisioner.call(payload: payload)

    sign_in(resource_name, user, store: false)

    render json: {
      message: "Signed in with Google.",
      user: user_payload(user)
    }, status: :ok
  rescue ActionController::ParameterMissing
    render json: {
      message: "Google sign-in failed.",
      errors: [ "id_token is required." ]
    }, status: :bad_request
  rescue GoogleIdTokenVerifier::VerificationError, Users::GoogleAccountProvisioner::ProvisioningError => e
    render json: {
      message: "Google sign-in failed.",
      errors: [ e.message ]
    }, status: :unauthorized
  end

  private

  def google_params
    params.permit(:id_token)
  end

  def user_payload(user)
    {
      id: user.id,
      email: user.email,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
