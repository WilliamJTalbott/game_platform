class UsersController < ApplicationController
  skip_before_action :require_authentication, only: [:new, :create]
  layout "no_sidebar", only: [:new, :create]

  def new
    @user = User.new
  end

  def show
    @user = User.find(params[:id])
  end

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for(@user)
      redirect_to root_path
    else
      render :new
    end
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update!(update_params)
      redirect_to user_path(@user)
    else
      render :edit
    end
  end

  def turbo_fetch
    @user = User.new(country: params.dig(:user, :country))
  end

  def update_params
    params.require(:user).permit(:name, :country, :state)
  end

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :name)
  end
end
