require 'digest/md5'

class Admin::ConfigController < ApplicationController
  before_filter :authenticate_admin!
  
  def console
    respond_to do |format|
      format.html
      format.js
    end
  end
end
