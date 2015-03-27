class ResourcesController < ApplicationController
  def server_icon
    server_icon = Server.server_icon

    return send_data server_icon, type: 'image/png', disposition: 'inline' if !!server_icon
    
    render file: "#{Rails.root}/public/404.html", status: 404
  end
end
