require "test_helper"

module Users
  class DirectoryServiceTest < ActiveSupport::TestCase
    test "returns users except current user" do
      users = DirectoryService.new(current_user: users(:one)).call

      assert_includes users, users(:two)
      assert_not_includes users, users(:one)
    end

    test "filters by query" do
      users = DirectoryService.new(current_user: users(:one), query: "two").call

      assert_equal [ users(:two) ], users.to_a
    end
  end
end
