require 'digest/md5'

class Admin::ConfigController < ApplicationController
  before_filter :authenticate_admin!
end
