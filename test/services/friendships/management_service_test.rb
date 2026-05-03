require "test_helper"

module Friendships
  class ManagementServiceTest < ActiveSupport::TestCase
    setup do
      @service = ManagementService.new(current_user: users(:two))
    end

    test "groups visible friendships" do
      groups = @service.grouped_friendships

      assert_equal 2, groups[:friendships].size
      assert_equal [ friendships(:accepted_request) ], groups[:accepted]
      assert_equal [ friendships(:pending_request) ], groups[:pending_received]
    end

    test "creates friendship from current user" do
      friendship = @service.create_friendship(addressee_id: users(:four).id)

      assert friendship.persisted?
      assert_equal users(:two), friendship.requester
      assert_equal users(:four), friendship.addressee
      assert_equal "pending", friendship.status
    end

    test "updates friendship status" do
      friendship = friendships(:pending_request)

      @service.update_status(friendship, :accepted)

      assert friendship.accepted?
    end

    test "checks participant and addressee" do
      friendship = friendships(:pending_request)

      assert @service.participant?(friendship)
      assert @service.addressee?(friendship)
    end
  end
end
