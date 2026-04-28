require "test_helper"
require "devise/jwt/test_helpers"

class ApiFlowsTest < ActionDispatch::IntegrationTest
  def auth_headers_for(user)
    Devise::JWT::TestHelpers.auth_headers({}, user)
  end

  def with_google_payload(payload)
    singleton_class = GoogleIdTokenVerifier.singleton_class
    original_method = GoogleIdTokenVerifier.method(:verify!)

    singleton_class.define_method(:verify!) do |id_token:|
      payload
    end

    yield
  ensure
    singleton_class.define_method(:verify!, original_method)
  end

  test "returns current user profile" do
    get "/me", headers: auth_headers_for(users(:one))

    assert_response :success
    assert_equal users(:one).email, response.parsed_body.dig("user", "email")
  end

  test "lists users except current user" do
    get "/users", headers: auth_headers_for(users(:one))

    assert_response :success
    returned_ids = response.parsed_body.fetch("users").map { |user| user.fetch("id") }

    assert_not_includes returned_ids, users(:one).id
    assert_includes returned_ids, users(:two).id
  end

  test "creates message for recipient" do
    assert_difference("Message.count", 1) do
      post "/messages",
           params: {
             message: {
               recipient_id: users(:three).id,
               body: "Fresh message"
             }
           },
           headers: auth_headers_for(users(:one)),
           as: :json
    end

    assert_response :created
    assert_equal users(:three).id, response.parsed_body.dig("message", "recipient", "id")
  end

  test "returns conversation between two users" do
    get "/messages/conversation/#{users(:two).id}", headers: auth_headers_for(users(:one))

    assert_response :success
    assert_equal users(:two).email, response.parsed_body.dig("user", "email")
    assert_equal 2, response.parsed_body.fetch("messages").size
  end

  test "creates friendship request" do
    assert_difference("Friendship.count", 1) do
      post "/friendships",
           params: { friendship: { addressee_id: users(:three).id } },
           headers: auth_headers_for(users(:one)),
           as: :json
    end

    assert_response :created
    assert_equal "pending", response.parsed_body.dig("friendship", "status")
  end

  test "accepts friendship request" do
    patch "/friendships/#{friendships(:pending_request).id}/accept",
          headers: auth_headers_for(users(:two)),
          as: :json

    assert_response :success
    assert_equal "accepted", response.parsed_body.dig("friendship", "status")
  end

  test "signs in with google and returns jwt" do
    google_payload = {
      "sub" => "google-sub-123",
      "email" => "google-user@gmail.com",
      "email_verified" => true
    }

    with_google_payload(google_payload) do
      assert_difference("User.count", 1) do
        post "/auth/google", params: { id_token: "valid-google-token" }, as: :json
      end
    end

    assert_response :success
    assert_equal "Signed in with Google.", response.parsed_body.fetch("message")
    assert_equal "google-user@gmail.com", response.parsed_body.dig("user", "email")
    assert_match(/^Bearer /, response.headers["Authorization"].to_s)
  end

  test "links an existing gmail account when signing in with google" do
    user = User.create!(
      email: "existing-user@gmail.com",
      password: "password123",
      password_confirmation: "password123"
    )

    google_payload = {
      "sub" => "google-sub-linked",
      "email" => user.email,
      "email_verified" => true
    }

    with_google_payload(google_payload) do
      assert_no_difference("User.count") do
        post "/auth/google", params: { id_token: "valid-google-token" }, as: :json
      end
    end

    assert_response :success
    assert_equal "google-sub-linked", user.reload.google_sub
  end

  test "rejects automatic linking for existing non authoritative email accounts" do
    user = User.create!(
      email: "person@example.com",
      password: "password123",
      password_confirmation: "password123"
    )

    google_payload = {
      "sub" => "google-sub-example",
      "email" => user.email,
      "email_verified" => true
    }

    with_google_payload(google_payload) do
      assert_no_difference("User.count") do
        post "/auth/google", params: { id_token: "valid-google-token" }, as: :json
      end
    end

    assert_response :unauthorized
    assert_nil user.reload.google_sub
  end
end
