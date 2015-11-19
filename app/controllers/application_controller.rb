include ApplicationHelper
include ActionView::Helpers::TextHelper

class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  add_flash_types :error, :info

  helper_method :admin_signed_in?
  helper_method :show_irc_web_chat?

  helper_method :slack_bot, :slack_groups_list

  helper_method :setup_params

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
  
  def slack_bot
    ServerCommand.slack_bot
  end
  
  def slack_groups_list
    # TODO Find a way to get AngularJS to refresh this correctly if a new API Key is provided.
    return [] unless !!slack_bot.auth_test
    groups = slack_bot.groups_list["groups"]
    
    @slack_groups_list = groups.map do |group|
      [group["name"], group["id"]]
    end
  end
private
  def admin_signed_in?
    session[:admin_signed_in]
  end
  
  def show_irc_web_chat?
    Preference.where(key: ['irc_enabled', 'irc_web_chat_enabled']).where(value: '1').count == 2
  end

  def setup_params
    @filter = params[:filter].present? ? params[:filter] : 'all'
    @query = params[:query]
    @sort_field = params[:sort_field].present? ? params[:sort_field] : 'created_at'
    @sort_order = params[:sort_order] == 'asc' ? 'asc' : 'desc'
  end
end
