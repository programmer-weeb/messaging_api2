require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "has sent and received message associations" do
    user = users(:one)

    assert_includes user.sent_messages, messages(:one)
    assert_includes user.received_messages, messages(:two)
  end

  test "has requested and received friendship associations" do
    user = users(:two)

    assert_includes user.received_friendships, friendships(:pending_request)
    assert_includes user.requested_friendships, friendships(:accepted_request)
  end
end
