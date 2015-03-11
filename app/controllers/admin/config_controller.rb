class Admin::ConfigController < ApplicationController
  before_filter :authenticate_admin!
  
  def show_server_properties
  end
end
