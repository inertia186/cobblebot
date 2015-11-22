require 'digest/md5'

class Admin::ConfigController < Admin::AdminController
  before_filter :authenticate_admin!

  def suggestions
    @key = params[:key]
    @verbose = params[:verbose]
    render "/admin/config/suggestions/#{@key.underscore}", layout: nil
  end

  def console
    respond_to do |format|
      format.html
      format.js
    end
  end
end
