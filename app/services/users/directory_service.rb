module Users
  class DirectoryService
    def initialize(current_user:, query: nil)
      @current_user = current_user
      @query = query
    end

    def call
      users = User.where.not(id: current_user.id).order(:email)
      users = users.where("email ILIKE ?", "%#{query}%") if query.present?
      users
    end

    private

    attr_reader :current_user, :query
  end
end
