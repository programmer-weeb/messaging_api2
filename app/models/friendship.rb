class Friendship < ApplicationRecord
  enum :status, { pending: 0, accepted: 1, blocked: 2 }, default: :pending

  belongs_to :requester, class_name: "User", inverse_of: :requested_friendships
  belongs_to :addressee, class_name: "User", inverse_of: :received_friendships

  validates :requester_id, uniqueness: { scope: :addressee_id }
  validates :status, presence: true
  validate :users_must_be_different

  private

  def users_must_be_different
    return if requester_id.blank? || addressee_id.blank?
    return unless requester_id == addressee_id

    errors.add(:addressee, "must be different from requester")
  end
end
