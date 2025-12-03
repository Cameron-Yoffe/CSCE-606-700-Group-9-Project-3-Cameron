class DashboardsController < ApplicationController
  before_action :require_login

  def show
    @user = current_user

    # User search
    if params[:search].present?
      @search_results = User.where("username LIKE ? OR email LIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
                            .where.not(id: current_user.id)
                            .limit(20)
    end

    # Activity feed from followed users
    followed_user_ids = current_user.following.pluck(:id)

    # Get recent diary entries from followed users
    @recent_diary_entries = DiaryEntry.where(user_id: followed_user_ids)
                                      .includes(:user, :movie)
                                      .order(created_at: :desc)
                                      .limit(20)

    # Get recent ratings from followed users
    @recent_ratings = Rating.where(user_id: followed_user_ids)
                            .includes(:user, :movie)
                            .order(created_at: :desc)
                            .limit(20)

    # Combined activity feed (merge and sort by created_at)
    @activity_feed = (@recent_diary_entries + @recent_ratings)
                     .sort_by(&:created_at)
                     .reverse
                     .first(30)

    # Suggested users to follow (users not followed yet, excluding self)
    @suggested_users = User.where.not(id: followed_user_ids + [ current_user.id ])
                           .order("RANDOM()")
                           .limit(5)
  end

  def search
    query = params[:q]

    if query.present?
      users = User.where("username LIKE ? OR email LIKE ?", "%#{query}%", "%#{query}%")
                  .where.not(id: current_user.id)
                  .limit(10)
                  .map do |user|
                    {
                      id: user.id,
                      username: user.username,
                      is_private: user.is_private?,
                      followers_count: user.followers.count,
                      is_following: current_user.following?(user),
                      is_requested: current_user.requested_follow?(user)
                    }
                  end

      render json: { users: users }
    else
      render json: { users: [] }
    end
  end

  private

  def require_login
    redirect_to sign_up_path, alert: "You must be logged in" unless logged_in?
  end
end
