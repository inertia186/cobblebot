class ResourcesController < ApplicationController
  caches_action :server_icon
  
  def server_icon
    head 304 and return unless request.env["HTTP_IF_NONE_MATCH"].to_s.empty?
    
    server_icon = Server.server_icon

    if !!server_icon
      response.headers['Expires'] = 2.hours.from_now.httpdate
      response.headers['Cache-Control'] = "max-age=#{2.hours.from_now.to_i / 1000}, public"
      response.headers['Pragma'] = 'cache'
      response.headers['ETag'] = 'server_icon'
      return send_data server_icon, filename: 'server-icon.png', type: 'image/png', disposition: 'inline'
    end
    
    render file: "#{Rails.root}/public/404.html", status: 404
  end
end
