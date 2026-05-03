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
    assert_includes friendship.errors[:base], "friendship already exists between these users"
  end

  test "reverse pair is rejected" do
    friendship = Friendship.new(
      requester: users(:two),
      addressee: users(:one),
      status: :pending
    )

    assert_not friendship.valid?
    assert_includes friendship.errors[:base], "friendship already exists between these users"
  end
end
