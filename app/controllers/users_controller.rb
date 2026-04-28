class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: :show

  def index
    users = Users::DirectoryService.new(current_user: current_user, query: params[:q]).call

    render json: { users: users.map { |user| user_payload(user) } }, status: :ok
  end

  def show
    render json: { user: user_payload(@user) }, status: :ok
  end

  def me
    render json: { user: user_payload(current_user) }, status: :ok
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_payload(user)
    {
      id: user.id,
      email: user.email,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
