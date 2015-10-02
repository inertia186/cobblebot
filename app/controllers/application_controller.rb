include ApplicationHelper
include ActionView::Helpers::TextHelper

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  add_flash_types :error, :info

  helper_method :admin_signed_in?
  helper_method :show_irc_web_chat?

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
    redirect_to new_admin_session_url unless admin_signed_in? || request.format == :atom
  end
  
  def http_authenticate_feed
    if request.format == :atom
      authenticate_or_request_with_http_basic("Feed Administration") do |user, password|
        password == Preference.web_admin_password
      end
    end
  end
private
  def admin_signed_in?
    session[:admin_signed_in]
  end
  
  def show_irc_web_chat?
    Preference.where(key: ['irc_enabled', 'irc_web_chat_enabled']).where(value: '1').count == 2
  end
end
