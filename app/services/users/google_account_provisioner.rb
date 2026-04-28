module Users
  class GoogleAccountProvisioner
    class ProvisioningError < StandardError; end

    def self.call(payload:)
      new(payload: payload).call
    end

    def initialize(payload:)
      @payload = payload.with_indifferent_access
    end

    def call
      raise ProvisioningError, "Google account email is not verified." unless email_verified?

      User.transaction do
        user = User.lock.find_by(google_sub: google_sub)
        return user if user

        existing_user = User.lock.find_by(email: email)
        return link_existing_user!(existing_user) if existing_user

        create_user!
      end
    rescue ActiveRecord::RecordInvalid => e
      raise ProvisioningError, e.record.errors.full_messages.to_sentence
    end

    private

    attr_reader :payload

    def google_sub
      payload.fetch(:sub)
    end

    def email
      payload.fetch(:email).downcase
    end

    def email_verified?
      ActiveModel::Type::Boolean.new.cast(payload[:email_verified])
    end

    def authoritative_email?
      email.ends_with?("@gmail.com") || payload[:hd].present?
    end

    def link_existing_user!(user)
      unless authoritative_email?
        raise ProvisioningError, "An account with this email already exists. Sign in with your password first before linking Google."
      end

      user.update!(google_sub: google_sub, confirmed_at: user.confirmed_at || Time.current)
      user
    end

    def create_user!
      password = Devise.friendly_token(32)

      User.create!(
        email: email,
        password: password,
        password_confirmation: password,
        google_sub: google_sub,
        confirmed_at: Time.current
      )
    end
  end
end
