require "test_helper"

class FriendshipTest < ActiveSupport::TestCase
  test "requester and addressee must differ" do
    friendship = Friendship.new(requester: users(:one), addressee: users(:one))

    assert_not friendship.valid?
    assert_includes friendship.errors[:addressee], "must be different from requester"
  end

  test "requester and addressee pair must be unique" do
    friendship = Friendship.new(
      requester: users(:one),
      addressee: users(:two),
      status: :accepted
    )

    assert_not friendship.valid?
    assert_includes friendship.errors[:requester_id], "has already been taken"
  end
end
