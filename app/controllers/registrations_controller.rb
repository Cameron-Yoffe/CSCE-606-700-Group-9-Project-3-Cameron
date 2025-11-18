class RegistrationsController < ApplicationController
  before_action :redirect_if_logged_in, only: [ :new, :create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      session[:user_id] = @user.id
      redirect_to dashboard_path, notice: "Account created successfully! Welcome to your movie diary."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_path, notice: "You have been logged out."
  end

  private

  def user_params
    params.require(:user).permit(:email, :username, :first_name, :last_name, :password, :password_confirmation)
  end

  def redirect_if_logged_in
    redirect_to dashboard_path if logged_in?
  end
end
