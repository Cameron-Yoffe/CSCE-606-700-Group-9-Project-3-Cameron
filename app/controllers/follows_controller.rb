class FollowsController < ApplicationController
  before_action :require_login
  before_action :set_user, only: %i[create]
  before_action :set_follow, only: %i[destroy accept reject]

  # POST /users/:user_id/follow
  def create
    if @user == current_user
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, alert: "You cannot follow yourself." }
        format.json { render json: { error: "You cannot follow yourself" }, status: :unprocessable_content }
      end
      return
    end

    follow = current_user.follow(@user)

    respond_to do |format|
      if follow&.persisted?
        message = follow.pending? ? "Follow request sent to #{@user.username}" : "You are now following #{@user.username}"
        format.html { redirect_back fallback_location: user_profile_path(@user), notice: message }
        format.json { render json: { status: follow.status, message: message }, status: :created }
      else
        format.html { redirect_back fallback_location: root_path, alert: "Unable to follow user." }
        format.json { render json: { error: "Unable to follow user" }, status: :unprocessable_content }
      end
    end
  end

  # DELETE /follows/:id
  def destroy
    user = @follow.followed
    was_pending = @follow.pending?
    @follow.destroy

    message = was_pending ? "Follow request to #{user.username} cancelled" : "You have unfollowed #{user.username}"

    respond_to do |format|
      format.html { redirect_back fallback_location: user_profile_path(user), notice: message }
      format.json { render json: { message: message }, status: :ok }
    end
  end

  # PATCH /follows/:id/accept
  def accept
    unless @follow.followed == current_user
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, alert: "You cannot accept this request." }
        format.json { render json: { error: "Unauthorized" }, status: :forbidden }
      end
      return
    end

    @follow.accept!

    respond_to do |format|
      format.html { redirect_back fallback_location: notifications_path, notice: "Follow request accepted" }
      format.json { render json: { status: "accepted", message: "Follow request accepted" }, status: :ok }
    end
  end

  # DELETE /follows/:id/reject
  def reject
    unless @follow.followed == current_user
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, alert: "You cannot reject this request." }
        format.json { render json: { error: "Unauthorized" }, status: :forbidden }
      end
      return
    end

    follower_username = @follow.follower.username
    @follow.reject!

    respond_to do |format|
      format.html { redirect_back fallback_location: notifications_path, notice: "Follow request from #{follower_username} rejected" }
      format.json { render json: { message: "Follow request rejected" }, status: :ok }
    end
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_follow
    @follow = Follow.find(params[:id])
  end

  def require_login
    redirect_to sign_up_path, alert: "You must be logged in" unless logged_in?
  end
end
