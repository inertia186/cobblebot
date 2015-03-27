class ResourcesController < ApplicationController
  def server_icon
    server_icon = Server.server_icon

    if !!server_icon
      response.headers["Expires"] = CGI.rfc1123_date(3600.seconds.from_now)
      return send_data server_icon, filename: 'server-icon.png', type: 'image/png', disposition: 'inline'
    end
    
    render file: "#{Rails.root}/public/404.html", status: 404
  end
end
