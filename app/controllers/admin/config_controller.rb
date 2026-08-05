class Admin::ConfigController < Admin::AdminController
  before_action :authenticate_admin!

  def show_server_properties
  end
end
