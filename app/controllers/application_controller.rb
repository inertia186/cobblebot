include ApplicationHelper
include ActionView::Helpers::TextHelper

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  add_flash_types :error, :info

  helper_method :admin_signed_in?

  before_filter :check_server_status, unless: Proc.new {
    [Admin, Api::V1].include? self.class.parent
  }

  def check_server_status
    unless Server.up?
      Rails.logger.error 'Minecraft Server is currently down.'
    
      render file: "#{Rails.root}/public/500.html", status: 500
    end
  end

  def authenticate_admin!
    redirect_to new_admin_session_url unless admin_signed_in?
  end
private
  def admin_signed_in?
    session[:admin_signed_in]
  end
end
