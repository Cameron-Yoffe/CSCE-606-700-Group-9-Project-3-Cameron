class DashboardsController < ApplicationController
  before_action :require_login

  def show
    @user = current_user
  end

  private

  def require_login
    redirect_to sign_up_path, alert: "You must be logged in" unless logged_in?
  end
end
