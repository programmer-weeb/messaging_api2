require "json"
require "jwt"
require "net/http"

class GoogleIdTokenVerifier
  JWKS_URL = URI("https://www.googleapis.com/oauth2/v3/certs")
  CACHE_KEY = "google_oidc_jwks"
  DEFAULT_CACHE_TTL = 1.hour
  ALGORITHMS = [ "RS256" ].freeze
  ISSUERS = [ "accounts.google.com", "https://accounts.google.com" ].freeze

  class VerificationError < StandardError; end

  def self.verify!(id_token:)
    new(id_token: id_token).verify!
  end

  def initialize(id_token:, cache: Rails.cache)
    @id_token = id_token
    @cache = cache
  end

  def verify!
    raise VerificationError, "Google ID token is missing." if id_token.blank?
    raise VerificationError, "GOOGLE_CLIENT_ID is not configured." if client_ids.empty?

    payload, = JWT.decode(
      id_token,
      nil,
      true,
      algorithms: ALGORITHMS,
      aud: client_ids,
      verify_aud: true,
      iss: ISSUERS,
      verify_iss: true,
      required_claims: %w[sub email exp],
      jwks: jwks_loader
    )

    raise VerificationError, "Google account email is not verified." unless email_verified?(payload)

    payload
  rescue JWT::DecodeError, JWT::JWKError, JSON::ParserError, SocketError, SystemCallError, OpenSSL::OpenSSLError => e
    raise VerificationError, "Google ID token could not be verified: #{e.message}"
  end

  private

  attr_reader :id_token, :cache

  def jwks_loader
    lambda do |options|
      cache.delete(CACHE_KEY) if options[:kid_not_found]
      fetch_jwks
    end
  end

  def fetch_jwks
    cache.read(CACHE_KEY) || refresh_jwks
  end

  def refresh_jwks
    response = Net::HTTP.start(JWKS_URL.host, JWKS_URL.port, use_ssl: true, read_timeout: 5, open_timeout: 5) do |http|
      http.get(JWKS_URL.request_uri)
    end

    raise VerificationError, "Google signing keys are unavailable." unless response.is_a?(Net::HTTPSuccess)

    jwks = JWT::JWK::Set.new(JSON.parse(response.body))
    jwks.select! { |key| key[:use].blank? || key[:use] == "sig" }

    cache.write(CACHE_KEY, jwks, expires_in: cache_ttl(response["cache-control"]))
    jwks
  end

  def cache_ttl(cache_control)
    match = cache_control.to_s.match(/max-age=(\d+)/)
    match ? match[1].to_i.seconds : DEFAULT_CACHE_TTL
  end

  def client_ids
    @client_ids ||= Array(
      Rails.application.credentials.dig(:google, :client_ids) ||
      ENV["GOOGLE_CLIENT_ID"]
    ).flatten.compact.map(&:to_s).reject(&:blank?)
  end

  def email_verified?(payload)
    ActiveModel::Type::Boolean.new.cast(payload["email_verified"])
  end
end
