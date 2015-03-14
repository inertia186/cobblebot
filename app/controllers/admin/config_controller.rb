require 'digest/md5'

class Admin::ConfigController < ApplicationController
  before_filter :authenticate_admin!
  
  def show_server_properties
    if !!server_properties['resource-pack']
      begin
        agent = Mechanize.new
        agent.keep_alive = false
        agent.open_timeout = 5
        agent.read_timeout = 5
        agent.get server_properties['resource-pack'].gsub(/\\/, '')

        @resource_pack_hash = Digest::MD5.hexdigest(agent.page.body) if agent.page
      rescue StandardError => e
        Rails.logger.error e.inspect
      end
    end
  end
end
