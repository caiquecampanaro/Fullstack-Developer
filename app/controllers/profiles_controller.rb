class ProfilesController < ApplicationController
  before_action :set_user

  def show
    authorize @user
  end

  def edit
    authorize @user
  end

  def update
    authorize @user

    # Handle password update separately
    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    if @user.update(user_params)
      redirect_to profile_path, notice: 'Profile updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @user

    @user.destroy
    sign_out @user
    redirect_to root_path, notice: 'Your account has been deleted successfully.'
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:full_name, :email, :avatar_url, :avatar_image, :password, :password_confirmation, :current_password)
  end
end
