class FriendshipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_friendship, only: [ :show, :accept, :block, :decline, :destroy ]
  before_action :authorize_participant!, only: [ :show, :destroy ]
  before_action :authorize_addressee!, only: [ :accept, :decline ]
  before_action :authorize_participant_for_block!, only: :block

  def index
    friendships = Friendship
                  .includes(:requester, :addressee)
                  .where(requester: current_user)
                  .or(Friendship.where(addressee: current_user))
                  .order(created_at: :desc)

    render json: {
      friendships: friendships.map { |friendship| friendship_payload(friendship) },
      accepted: friendships.select(&:accepted?).map { |friendship| friendship_payload(friendship) },
      pending_sent: friendships.select { |friendship| friendship.pending? && friendship.requester_id == current_user.id }
                               .map { |friendship| friendship_payload(friendship) },
      pending_received: friendships.select { |friendship| friendship.pending? && friendship.addressee_id == current_user.id }
                                   .map { |friendship| friendship_payload(friendship) },
      blocked: friendships.select(&:blocked?).map { |friendship| friendship_payload(friendship) }
    }, status: :ok
  end

  def show
    render json: { friendship: friendship_payload(@friendship) }, status: :ok
  end

  def create
    friendship = current_user.requested_friendships.build(friendship_params)

    if friendship.save
      render json: { friendship: friendship_payload(friendship) }, status: :created
    else
      render_unprocessable(friendship)
    end
  end

  def accept
    update_status!(:accepted)
  end

  def block
    update_status!(:blocked)
  end

  def decline
    @friendship.destroy
    head :no_content
  end

  def destroy
    @friendship.destroy
    head :no_content
  end

  private

  def set_friendship
    @friendship = Friendship.includes(:requester, :addressee).find(params[:id])
  end

  def authorize_participant!
    return if participant?(@friendship)

    render_forbidden
  end

  def authorize_addressee!
    return if @friendship.addressee_id == current_user.id

    render_forbidden("Only addressee can update this friendship request.")
  end

  def authorize_participant_for_block!
    return if participant?(@friendship)

    render_forbidden
  end

  def participant?(friendship)
    friendship.requester_id == current_user.id || friendship.addressee_id == current_user.id
  end

  def friendship_params
    params.require(:friendship).permit(:addressee_id)
  end

  def update_status!(status)
    if @friendship.update(status: status)
      render json: { friendship: friendship_payload(@friendship) }, status: :ok
    else
      render_unprocessable(@friendship)
    end
  end

  def friendship_payload(friendship)
    {
      id: friendship.id,
      status: friendship.status,
      created_at: friendship.created_at,
      updated_at: friendship.updated_at,
      requester: user_payload(friendship.requester),
      addressee: user_payload(friendship.addressee)
    }
  end

  def user_payload(user)
    {
      id: user.id,
      email: user.email
    }
  end
end
