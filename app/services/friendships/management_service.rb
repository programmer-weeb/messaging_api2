module Friendships
  class ManagementService
    def initialize(current_user:)
      @current_user = current_user
    end

    def visible_friendships
      Friendship
        .includes(:requester, :addressee)
        .where(requester: current_user)
        .or(Friendship.where(addressee: current_user))
        .order(created_at: :desc)
    end

    def grouped_friendships
      friendships = visible_friendships.to_a

      {
        friendships: friendships,
        accepted: friendships.select(&:accepted?),
        pending_sent: friendships.select { |friendship| friendship.pending? && friendship.requester_id == current_user.id },
        pending_received: friendships.select { |friendship| friendship.pending? && friendship.addressee_id == current_user.id },
        blocked: friendships.select(&:blocked?)
      }
    end

    def create_friendship(attributes)
      current_user.requested_friendships.create(attributes)
    end

    def participant?(friendship)
      friendship.requester_id == current_user.id || friendship.addressee_id == current_user.id
    end

    def addressee?(friendship)
      friendship.addressee_id == current_user.id
    end

    def update_status(friendship, status)
      friendship.tap { |record| record.update(status: status) }
    end

    private

    attr_reader :current_user
  end
end
