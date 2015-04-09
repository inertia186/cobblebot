class Admin::SessionsController < Admin::AdminController
  before_filter :authenticate_admin!, except: [:new, :create]

  def new
  end

  def create
    if params[:admin_password] == Preference.web_admin_password
      sign_in_admin
    else
      redirect_to new_admin_session_url, error: 'Password incorrect.' and return
    end
    
    redirect_to admin_preferences_url
  end

  def destroy
    session.destroy
    
    redirect_to new_admin_session_url, info: 'You have been logged out.'
  end
end