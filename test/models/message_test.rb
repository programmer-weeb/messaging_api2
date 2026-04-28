require "test_helper"

class MessageTest < ActiveSupport::TestCase
  test "requires body" do
    message = Message.new(sender: users(:one), recipient: users(:two), body: "")

    assert_not message.valid?
    assert_includes message.errors[:body], "can't be blank"
  end

  test "belongs to sender and recipient" do
    message = messages(:one)

    assert_equal users(:one), message.sender
    assert_equal users(:two), message.recipient
  end
end
