require 'digest/md5'

class Admin::ConfigController < Admin::AdminController
  before_filter :authenticate_admin!
  
  def console
    respond_to do |format|
      format.html
      format.js
    end
  end
end
