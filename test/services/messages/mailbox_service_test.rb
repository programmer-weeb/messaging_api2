require "test_helper"

module Messages
  class MailboxServiceTest < ActiveSupport::TestCase
    setup do
      @service = MailboxService.new(current_user: users(:one))
    end

    test "returns visible messages" do
      assert_equal [ messages(:two), messages(:one) ], @service.inbox.to_a
    end

    test "groups conversations by partner" do
      conversations = @service.conversations

      assert_equal 1, conversations.size
      assert_equal users(:two), conversations.first[:user]
      assert_equal messages(:two), conversations.first[:latest_message]
      assert_equal 2, conversations.first[:messages_count]
    end

    test "creates message for current user as sender" do
      message = @service.create_message(recipient_id: users(:three).id, body: "Service made this")

      assert message.persisted?
      assert_equal users(:one), message.sender
      assert_equal users(:three), message.recipient
    end

    test "checks participation" do
      assert @service.participant?(messages(:one))
      assert @service.sender?(messages(:one))
      assert_not @service.sender?(messages(:two))
    end
  end
end
