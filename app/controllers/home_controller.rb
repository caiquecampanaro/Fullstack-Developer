class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]

  def index
    redirect_to admin_dashboard_path if user_signed_in? && current_user.admin?
    redirect_to profile_path if user_signed_in? && !current_user.admin?
  end
end

