class NotificationsController < ApplicationController
  before_action :require_login
  before_action :set_notification, only: %i[mark_as_read]

  # GET /notifications
  def index
    @notifications = current_user.notifications.recent.includes(notifiable: %i[follower followed])
    @unread_count = current_user.unread_notifications_count
  end

  # PATCH /notifications/:id/mark_as_read
  def mark_as_read
    @notification.mark_as_read!

    respond_to do |format|
      format.html { redirect_back fallback_location: notifications_path }
      format.json { render json: { read: true }, status: :ok }
    end
  end

  # PATCH /notifications/mark_all_as_read
  def mark_all_as_read
    current_user.notifications.unread.update_all(read: true)

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: "All notifications marked as read" }
      format.json { render json: { message: "All notifications marked as read" }, status: :ok }
    end
  end

  # DELETE /notifications/destroy_all
  def destroy_all
    current_user.notifications.destroy_all

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: "All notifications deleted" }
      format.json { render json: { message: "All notifications deleted" }, status: :ok }
    end
  end

  # GET /notifications/unread_count
  def unread_count
    render json: { count: current_user.unread_notifications_count }
  end

  private

  def set_notification
    @notification = current_user.notifications.find(params[:id])
  end

  def require_login
    redirect_to sign_up_path, alert: "You must be logged in" unless logged_in?
  end
end
