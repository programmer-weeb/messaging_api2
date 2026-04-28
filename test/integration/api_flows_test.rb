require "test_helper"
require "devise/jwt/test_helpers"

class ApiFlowsTest < ActionDispatch::IntegrationTest
  def auth_headers_for(user)
    Devise::JWT::TestHelpers.auth_headers({}, user)
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
end
