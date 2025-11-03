class Users::SessionsController < Devise::SessionsController
  protected

  def after_sign_in_path_for(resource)
    if resource.admin?
      admin_dashboard_path
    else
      profile_path
    end
  end
end

