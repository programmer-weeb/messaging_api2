class FriendshipsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_management_service
  before_action :set_friendship, only: [ :show, :accept, :block, :decline, :destroy ]
  before_action :authorize_participant!, only: [ :show, :destroy ]
  before_action :authorize_addressee!, only: [ :accept, :decline ]
  before_action :authorize_participant_for_block!, only: :block

  def index
    friendship_groups = @management_service.grouped_friendships

    render json: {
      friendships: friendship_groups[:friendships].map { |friendship| friendship_payload(friendship) },
      accepted: friendship_groups[:accepted].map { |friendship| friendship_payload(friendship) },
      pending_sent: friendship_groups[:pending_sent].map { |friendship| friendship_payload(friendship) },
      pending_received: friendship_groups[:pending_received].map { |friendship| friendship_payload(friendship) },
      blocked: friendship_groups[:blocked].map { |friendship| friendship_payload(friendship) }
    }, status: :ok
  end

  def show
    render json: { friendship: friendship_payload(@friendship) }, status: :ok
  end

  def create
    friendship = @management_service.create_friendship(friendship_params)

    if friendship.persisted?
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

  def set_management_service
    @management_service = Friendships::ManagementService.new(current_user: current_user)
  end

  def authorize_participant!
    return if @management_service.participant?(@friendship)

    render_forbidden
  end

  def authorize_addressee!
    return if @management_service.addressee?(@friendship)

    render_forbidden("Only addressee can update this friendship request.")
  end

  def authorize_participant_for_block!
    return if @management_service.participant?(@friendship)

    render_forbidden
  end

  def friendship_params
    params.require(:friendship).permit(:addressee_id)
  end

  def update_status!(status)
    if @management_service.update_status(@friendship, status).valid?
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
