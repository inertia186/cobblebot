class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :sign_in_admin
  helper_method :admin_signed_in?

  def authenticate_admin!
    redirect_to new_admin_session_url unless admin_signed_in?
  end
  
  def sign_in_admin
    session[:admin_signed_in] = true
  end

  def admin_signed_in?
    session[:admin_signed_in]
  end
end
